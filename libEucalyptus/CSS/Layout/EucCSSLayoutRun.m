//
//  EucCSSLayoutRun.m
//  LibCSSTest
//
//  Created by James Montgomerie on 12/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif

#import "EucCSSInternal.h"
#import "EucCSSLayouter.h"
#import "EucCSSLayoutRun.h"
#import "EucCSSLayoutRun_Package.h"
#import "EucCSSLayoutPositionedRun.h"
#import "EucCSSLayoutPositionedLine.h"
#import "EucCSSLayoutPositionedBlock.h"
#import "EucCSSIntermediateDocument.h"
#import "EucCSSIntermediateDocument_Package.h"
#import "EucCSSIntermediateDocumentConcreteNode.h"
#import "EucCSSIntermediateDocumentGeneratedTextNode.h"
#import "EucCSSIntermediateDocumentNode.h"
#import "EucCSSDocumentTreeNode.h"
#import "THStringRenderer.h"
#import "THCache.h"
#import "THNSStringSmartQuotes.h"
#import "THPair.h"
#import "THLog.h"
#import "th_just_with_floats.h"

#import "EucSharedHyphenator.h"

#import <libcss/libcss.h>
#import <pthread.h>
#import <objc/runtime.h>

typedef struct EucCSSLayoutRunBreakInfo {
    EucCSSLayoutRunPoint point;
    BOOL consumesComponent;
} EucCSSLayoutRunBreakInfo;

@interface EucCSSLayoutRun ()
- (void)_addComponent:(EucCSSLayoutRunComponentInfo *)info;
- (void)_accumulateTextNode:(EucCSSIntermediateDocumentNode *)subnode;
- (void)_accumulateImageNode:(EucCSSIntermediateDocumentNode *)subnode;
- (void)_accumulateFloatNode:(EucCSSIntermediateDocumentNode *)subnode;
@end 

@implementation EucCSSLayoutRun

@synthesize componentInfos = _componentInfos;
@synthesize componentsCount = _componentsCount;
@synthesize wordToComponent = _wordToComponent;

@synthesize sizeDependentComponentIndexes = _sizeDependentComponentIndexes;
@synthesize floatComponentIndexes = _floatComponentIndexes;

@synthesize id = _id;
@synthesize document = _document;
@synthesize startNode = _startNode;
@synthesize underNode = _underNode;
@synthesize nextNodeUnderLimitNode = _nextNodeUnderLimitNode;
@synthesize nextNodeInDocument = _nextNodeInDocument;

@synthesize wordsCount = _wordsCount;


#define RUN_CACHE_CAPACITY 256
static NSString * const EucCSSRunCacheKey = @"EucCSSRunCacheKey";

+ (id)runWithNode:(EucCSSIntermediateDocumentNode *)inlineNode 
   underLimitNode:(EucCSSIntermediateDocumentNode *)underNode
   stopBeforeNode:(EucCSSIntermediateDocumentNode *)stopBeforeNode
            forId:(uint32_t)id
{
    EucCSSLayoutRun *ret = nil;
    
    EucCSSIntermediateDocument *document = inlineNode.document;
    @synchronized(document) {
        THIntegerToObjectCache *cachedRuns = objc_getAssociatedObject(document, EucCSSRunCacheKey);
        if(!cachedRuns) {
            cachedRuns = [[THIntegerToObjectCache alloc] init];
            cachedRuns.generationLifetime = RUN_CACHE_CAPACITY;
            cachedRuns.conserveItemsInUse = YES;
            objc_setAssociatedObject(document, EucCSSRunCacheKey, cachedRuns, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [cachedRuns release];
        }
        ret = [cachedRuns objectForKey:id];
        if(!ret) {
            ret = [[[self class] alloc] initWithNode:inlineNode
                                      underLimitNode:underNode 
                                      stopBeforeNode:stopBeforeNode
                                               forId:id];
            [cachedRuns cacheObject:ret forKey:id];
            [ret autorelease];
        } else {
            if(THWillLog()) {
                NSParameterAssert(ret.startNode == inlineNode && ret.underNode == underNode);
            }
        }
    }
    return ret;
}
 
- (id)initWithNode:(EucCSSIntermediateDocumentNode *)inlineNode 
    underLimitNode:(EucCSSIntermediateDocumentNode *)underNode
    stopBeforeNode:(EucCSSIntermediateDocumentNode *)stopBeforeNode
             forId:(uint32_t)id
{
    if((self = [super init])) {        
        _sharedHyphenator = [[EucSharedHyphenator sharedHyphenator] retain];

        _id = id;
        
        _startNode = [inlineNode retain];
        _underNode = [underNode retain];
        
        // Retain this, because we're retaining nodes, but nodes don't retain
        // their documents.
        // No need to do this - noone should be using the run after the 
        // document's gone.
        //_document = [_startNode.document retain];        
        _document = _startNode.document;        
        
        css_computed_style *inlineNodeStyle = inlineNode.computedStyle;
                
        // _wordToComponent is 1-indexed for words - word '0' is the start of 
        // this run - so set that up now.
        _wordToComponentCapacity = 128;
        _wordToComponent = (uint32_t *)malloc(_wordToComponentCapacity * sizeof(uint32_t));
        _wordToComponent[0] = 0;         
        
        BOOL reachedLimit = NO;
        
        EucCSSLayoutRunComponentInfo currentComponentInfo = { EucCSSLayoutRunComponentKindNone };
        static const EucCSSLayoutRunComponentInfo hardBreakInfo = { EucCSSLayoutRunComponentKindHardBreak };
        
        BOOL wasFloat = NO;
        while(YES) {
            if(inlineNode == stopBeforeNode) {
                break;
            }            
            
            EucCSSIntermediateDocumentNode *nextNode = nil;
            
            if(inlineNode.isTextNode) {
                [self _accumulateTextNode:inlineNode];
                nextNode = [inlineNode nextDisplayableUnder:underNode];
            } else if(inlineNode.isImageNode) {
                [self _accumulateImageNode:inlineNode];
                nextNode = [inlineNode nextDisplayableUnder:underNode];
            } else if(inlineNodeStyle) {
                if(css_computed_float(inlineNodeStyle) != CSS_FLOAT_NONE) {
                    [self _accumulateFloatNode:inlineNode];
                    nextNode = [inlineNode.parent displayableNodeAfter:inlineNode under:underNode];
                    wasFloat = YES;
                } else { 
                    enum css_display_e inlineNodeDisplay = (enum css_display_e)inlineNode.display;
                    if(inlineNodeDisplay == CSS_DISPLAY_INLINE || inlineNodeDisplay == CSS_DISPLAY_LIST_ITEM) {
                        // Open this node.
                        if(inlineNodeDisplay == CSS_DISPLAY_LIST_ITEM) {
                            if(_componentsCount > 0 && _componentInfos[_componentsCount - 1].kind != EucCSSLayoutRunComponentKindHardBreak) {
                                EucCSSLayoutRunComponentInfo info = hardBreakInfo;
                                info.documentNode = inlineNode.parent;
                                [self _addComponent:&info];
                            } 
                            
                            // This is a bit of a hack to ensure we don't put extra spaces from the end 
                            // of previous lines inside a list item.  The need for this may signify a 
                            // deeper problem...
                            _previousInlineCharacterWasSpace = YES;
                            _alreadyInsertedSpace = YES;
                        }
                        
                        currentComponentInfo.kind = EucCSSLayoutRunComponentKindOpenNode;
                        currentComponentInfo.documentNode = inlineNode;
                        [self _addComponent:&currentComponentInfo];
                        nextNode = [inlineNode nextDisplayableUnder:underNode];
                    } else {
                        break;
                    }
                }
            } else {
                break;   
            }
            
            if(nextNode) {
                EucCSSIntermediateDocumentNode *nextNodeParent = nextNode.parent;
                while(inlineNode != nextNodeParent && 
                      inlineNode != underNode) {
                    if(!inlineNode.isTextNode && 
                       !inlineNode.isImageNode &&
                       (!inlineNodeStyle || css_computed_float(inlineNodeStyle) == CSS_FLOAT_NONE)) {
                        if(currentComponentInfo.documentNode != inlineNode) {
                            // We can close nodes that we didn't start if we're in
                            // an inline node with block nodes within it, so we
                            // need to populate this if we didn't above (usually,
                            // it's populated on node open).
                            currentComponentInfo.documentNode = inlineNode;
                        }
                        currentComponentInfo.kind = EucCSSLayoutRunComponentKindCloseNode;
                        [self _addComponent:&currentComponentInfo];
                        
                        if(inlineNode.display == CSS_DISPLAY_LIST_ITEM) {
                            EucCSSLayoutRunComponentInfo info = hardBreakInfo;
                            info.documentNode = inlineNode.parent;
                            [self _addComponent:&info];
                            _previousInlineCharacterWasSpace = YES;
                            _alreadyInsertedSpace = YES;
                        }
                    }                    
                    inlineNode = inlineNode.parent;
                    inlineNodeStyle = inlineNode.computedStyle;
                }

                inlineNode = nextNode;
                inlineNodeStyle = inlineNode.computedStyle;
            } else {
                if(wasFloat) {
                    inlineNode = [inlineNode.parent displayableNodeAfter:inlineNode under:nil];
                } else {
                    inlineNode = [inlineNode nextDisplayable];
                }
                reachedLimit = YES;
                break;
            }
            if(wasFloat) {
                wasFloat = NO;
            }
        }    
        
        if(!reachedLimit) {
            _nextNodeUnderLimitNode = [inlineNode retain];
        } 
        _nextNodeInDocument = [inlineNode retain];
    }
    return self;
}

- (void)dealloc
{
    for(uint32_t i = 0; i < _componentsCount; ++i) {
        [_componentInfos[i].documentNode release];

        EucCSSLayoutRunComponentKind kind = _componentInfos[i].kind;
        if(kind == EucCSSLayoutRunComponentKindWord) {
            [_componentInfos[i].contents.stringInfo.string release];
        } else if (kind == EucCSSLayoutRunComponentKindImage) { 
            [_componentInfos[i].contents.imageInfo.imageURL release];
        } else if(kind == EucCSSLayoutRunComponentKindHyphenationRule) {
            [_componentInfos[i].contents.hyphenationInfo.beforeHyphen release];
            [_componentInfos[i].contents.hyphenationInfo.afterHyphen release];
        }
    }
    free(_componentInfos);
    free(_wordToComponent);

    [_startNode release];
    [_underNode release];
    [_nextNodeUnderLimitNode release];
    [_nextNodeInDocument release];

    [_sizeDependentComponentIndexes release];
    [_floatComponentIndexes release];
    
    // See comments in init.
    //[_document release];
    
    [_sharedHyphenator release];
    
    [super dealloc];
}

- (CGFloat)textIndentInWidth:(CGFloat)width atScaleFactor:(CGFloat)scaleFactor
{
    CGFloat ret = 0.0f;
    
    css_computed_style *style = _startNode.blockLevelNode.computedStyle;
    if(style) {
        css_fixed length = 0;
        css_unit unit = (css_unit)0;
        css_computed_text_indent(style, &length, &unit);
        ret = EucCSSLibCSSSizeToPixels(style, length, unit, width, scaleFactor);
    }
    return ret;
}

- (uint8_t)textAlign
{
    uint8_t ret = CSS_TEXT_ALIGN_DEFAULT;
    
    css_computed_style *style = _startNode.blockLevelNode.computedStyle;
    if(style) {
        ret = css_computed_text_align(style);
    }
    return ret;
}

- (void)_addComponent:(EucCSSLayoutRunComponentInfo *)info
{
    if(info->kind == EucCSSLayoutRunComponentKindWord) {
        ++_wordsCount;
        if(_wordToComponentCapacity == _wordsCount) {
            _wordToComponentCapacity += 128;
            _wordToComponent = (uint32_t *)realloc(_wordToComponent, _wordToComponentCapacity * sizeof(uint32_t));
        }
        _wordToComponent[_wordsCount] = _componentsCount;
        _currentWordElementCount = 0;
        
        [info->contents.stringInfo.string retain];
    } else if(info->kind == EucCSSLayoutRunComponentKindImage) {
        [info->contents.imageInfo.imageURL retain];
    } else if(info->kind == EucCSSLayoutRunComponentKindHyphenationRule) {
        [info->contents.hyphenationInfo.beforeHyphen retain];
        [info->contents.hyphenationInfo.afterHyphen retain];
    }
    
    if(_componentsCapacity == _componentsCount) {
        _componentsCapacity += 128;
        _componentInfos = (EucCSSLayoutRunComponentInfo *)realloc(_componentInfos, _componentsCapacity * sizeof(EucCSSLayoutRunComponentInfo));
    }
    
    info->point.word = _wordsCount;
    info->point.element = _currentWordElementCount;
    
    [info->documentNode retain];
    
    _componentInfos[_componentsCount] = *info;
    
    ++_componentsCount;
    ++_currentWordElementCount;
}

- (void)_accumulateImageNode:(EucCSSIntermediateDocumentNode *)subnode
{
    NSURL *imageURL = [subnode imageSource];
    EucCSSLayoutRunComponentInfo info = { 0 };
    info.documentNode = subnode;
    info.kind = EucCSSLayoutRunComponentKindImage;
    info.contents.imageInfo.imageURL = imageURL;
    [self _addComponent:&info];
    
    if(!_sizeDependentComponentIndexes) {
        _sizeDependentComponentIndexes = [[NSMutableArray alloc] init];
    }
    [_sizeDependentComponentIndexes addObject:[NSNumber numberWithInteger:_componentsCount - 1]];
    
    _previousInlineCharacterWasSpace = NO;
}

- (void)_accumulateTextNode:(EucCSSIntermediateDocumentNode *)subnode 
{
    css_computed_style *subnodeStyle;
    subnodeStyle = [subnode.parent computedStyle];
    
    enum css_white_space_e whiteSpaceModel = (enum css_white_space_e)css_computed_white_space(subnodeStyle);
    
    EucCSSLayoutRunComponentInfo spaceInfo = { 0 };
    spaceInfo.kind = EucCSSLayoutRunComponentKindSpace;
    spaceInfo.documentNode = subnode;
    
    uint8_t textAlign = [self textAlign];
    
    // CSS3 may have a way of specifying this.
    BOOL shouldHyphenate =  (textAlign == CSS_TEXT_ALIGN_LEFT || textAlign == CSS_TEXT_ALIGN_JUSTIFY) && 
                            !(whiteSpaceModel == CSS_WHITE_SPACE_PRE_LINE ||
                              whiteSpaceModel == CSS_WHITE_SPACE_PRE ||
                              whiteSpaceModel == CSS_WHITE_SPACE_PRE_WRAP);
    
    NSArray *preprocessedWords = subnode.preprocessedWords;
    if(preprocessedWords) {
        if(preprocessedWords.count) {
            for(NSString *word in preprocessedWords) {
                if(_previousInlineCharacterWasSpace && _seenNonSpace && !_alreadyInsertedSpace) {
                    [self _addComponent:&spaceInfo];                                    
                }
                
                word = [word stringWithSmartQuotes];
                
                EucCSSLayoutRunComponentInfo info = spaceInfo;
                info.kind = EucCSSLayoutRunComponentKindWord;
                info.contents.stringInfo.string = word;
                [self _addComponent:&info];
                
                if(shouldHyphenate && word.length > 4) {
                    NSArray *hyphenations = [_sharedHyphenator hyphenationsForWord:word];
                    
                    EucCSSLayoutRunComponentInfo hyphenInfo = info;
                    hyphenInfo.kind = EucCSSLayoutRunComponentKindHyphenationRule;
                    
                    for(THPair *hyphenatedPair in hyphenations) {
                        NSString *beforeBreak = hyphenatedPair.first;
                        hyphenInfo.contents.hyphenationInfo.beforeHyphen = beforeBreak;
                        
                        NSString *afterBreak = hyphenatedPair.second;
                        hyphenInfo.contents.hyphenationInfo.afterHyphen = afterBreak;
                        
                        [self _addComponent:&hyphenInfo];
                    }
                }
                
                if(!_seenNonSpace) {
                    _seenNonSpace = YES;
                }
                if(_alreadyInsertedSpace) {
                    _alreadyInsertedSpace = NO;
                }
                if(!_previousInlineCharacterWasSpace) {
                    _previousInlineCharacterWasSpace = YES;
                }
            }            
        }
    } else {
        CFStringRef text = (CFStringRef)subnode.text;
        CFIndex textLength = CFStringGetLength(text);
        if(textLength) {
            UniChar *charactersToFree = NULL;
            const UniChar *characters = CFStringGetCharactersPtr(text);
            if(characters == NULL) {
                // CFStringGetCharactersPtr may return NULL at any time.
                charactersToFree = (UniChar *)malloc(sizeof(UniChar) * textLength);
                CFStringGetCharacters(text,
                                      CFRangeMake(0, textLength),
                                      charactersToFree);
                characters = charactersToFree;
            }
            
            const UniChar *cursor = characters;
            const UniChar *end = characters + textLength;
            
            const UniChar *wordStart = cursor;
            
            BOOL wordNeedsSmartQuotes = NO;
            BOOL sawNewline = NO;
            while(cursor < end) {
                UniChar ch = *cursor;
                switch(ch) {
                    case 0x000A: // LF
                    case 0x000D: // CR
                        if(!sawNewline) {
                            sawNewline = YES;
                        }
                        // No break - fall through.
                    case 0x0009: // tab
                    case 0x0020: // Space
                    case 0x00A0: // Non-breaking Space
                        if(!_previousInlineCharacterWasSpace) {
                            if(wordStart != cursor) {
                                CFIndex wordLength = cursor - wordStart;
                                CFStringRef string = CFStringCreateWithCharacters(kCFAllocatorDefault,
                                                                                  wordStart, 
                                                                                  wordLength);
                                if(string) {
                                    if(wordNeedsSmartQuotes) {
                                        NSString *smartQuoted = [(NSString *)string stringWithSmartQuotesWithPreviousCharacter:_characterBeforeWord];
                                        CFRelease(string);
                                        string = (CFStringRef)[smartQuoted retain];
                                        wordNeedsSmartQuotes = NO;
                                    }
                                    EucCSSLayoutRunComponentInfo info = spaceInfo;
                                    info.kind = EucCSSLayoutRunComponentKindWord;
                                    info.contents.stringInfo.string = (NSString *)string;
                                    [self _addComponent:&info];
                                    
                                    if(shouldHyphenate && wordLength > 4) {
                                        NSArray *hyphenations = [_sharedHyphenator hyphenationsForWord:(NSString *)string];
                                        
                                        EucCSSLayoutRunComponentInfo hyphenInfo = info;
                                        hyphenInfo.kind = EucCSSLayoutRunComponentKindHyphenationRule;
                                        
                                        for(THPair *hyphenatedPair in hyphenations) {
                                            NSString *beforeBreak = hyphenatedPair.first;
                                            hyphenInfo.contents.hyphenationInfo.beforeHyphen = beforeBreak;
                                            
                                            NSString *afterBreak = hyphenatedPair.second;
                                            hyphenInfo.contents.hyphenationInfo.afterHyphen = afterBreak;
                                            
                                            [self _addComponent:&hyphenInfo];
                                        }
                                    }
                                    CFRelease(string);
                                }
                            }
                            if(ch == 0x00A0) {
                                EucCSSLayoutRunComponentInfo info = spaceInfo;
                                info.kind = EucCSSLayoutRunComponentKindNonbreakingSpace;
                                [self _addComponent:&info];
                                wordStart = cursor + 1;
                            } else {
                                _previousInlineCharacterWasSpace = YES;
                            }
                            _characterBeforeWord = ' ';
                        }
                        if(whiteSpaceModel == CSS_WHITE_SPACE_PRE ||
                           whiteSpaceModel == CSS_WHITE_SPACE_PRE_WRAP ||
                           whiteSpaceModel == CSS_WHITE_SPACE_PRE_LINE) {
                            switch(ch) {
                                case 0x000A:
                                {
                                    EucCSSLayoutRunComponentInfo info = spaceInfo;
                                    info.kind = EucCSSLayoutRunComponentKindHardBreak;
                                    [self _addComponent:&info];
                                    _alreadyInsertedSpace = YES;
                                    break;  
                                }
                                case 0x0009:
                                case 0x0020:
                                {
                                    if(whiteSpaceModel == CSS_WHITE_SPACE_PRE ||
                                       whiteSpaceModel == CSS_WHITE_SPACE_PRE_WRAP) {
                                        [self _addComponent:&spaceInfo];
                                        _alreadyInsertedSpace = YES;
                                    }
                                    break;
                                }
                            }
                        }
                        break;
                        
                    case '\'':
                    case '"':
                        wordNeedsSmartQuotes = YES;
                        // Fall through.
                    default:
                        if(_previousInlineCharacterWasSpace) {
                            if(!_alreadyInsertedSpace) {
                                [self _addComponent:&spaceInfo];
                            } else {
                                _alreadyInsertedSpace = NO;
                            }
                            wordStart = cursor;
                            _previousInlineCharacterWasSpace = NO;
                            if(!_seenNonSpace) {
                                _seenNonSpace = YES;
                            }
                        }
                }
                ++cursor;
            }
            if(!_previousInlineCharacterWasSpace) {
                CFStringRef string = CFStringCreateWithCharacters(kCFAllocatorDefault,
                                                                  wordStart, 
                                                                  cursor - wordStart);
                if(string) {
                    if(wordNeedsSmartQuotes) {
                        NSString *smartQuoted = [(NSString *)string stringWithSmartQuotesWithPreviousCharacter:_characterBeforeWord];
                        CFRelease(string);
                        string = (CFStringRef)[smartQuoted retain];
                        wordNeedsSmartQuotes = NO;
                    }                    
                    EucCSSLayoutRunComponentInfo info = spaceInfo;
                    info.kind = EucCSSLayoutRunComponentKindWord;
                    info.contents.stringInfo.string = (NSString *)string;
                    [self _addComponent:&info];
                    CFRelease(string);
                }
            } 
            if(_previousInlineCharacterWasSpace) {
                if(!_alreadyInsertedSpace && _seenNonSpace) {
                    // Check _seenNonSpace because we're not supposed to add spaces at the /start/ of lines.
                    [self _addComponent:&spaceInfo];
                    _alreadyInsertedSpace = YES;
                }
            }
            
            _characterBeforeWord = *(cursor - 1);
            
            if(charactersToFree) {
                free(charactersToFree);
            }
        }
    }
}

- (void)_accumulateFloatNode:(EucCSSIntermediateDocumentNode *)subnode
{
    EucCSSLayoutRunComponentInfo info = { 0 };
    info.documentNode = subnode;
    info.kind = EucCSSLayoutRunComponentKindFloat;
    [self _addComponent:&info];    
    
    if(!_floatComponentIndexes) {
        _floatComponentIndexes = [[NSMutableArray alloc] init];
    }
    [_floatComponentIndexes addObject:[NSNumber numberWithInteger:_componentsCount - 1]];    
}

- (uint32_t)pointToComponentOffset:(EucCSSLayoutRunPoint)point
{
    if(point.word > _wordsCount) {
        // This is an 'off the end' marker (i.e. an endpoint to line that
        // is 'after' the last word).
        return _componentsCount;
    } else {
        return _wordToComponent[point.word] + point.element;
    }
}

- (EucCSSLayoutRunPoint)pointForNode:(EucCSSIntermediateDocumentNode *)node
{
    for(size_t i = 0; i < _componentsCount; ++i) {
        if(_componentInfos[i].documentNode == node) {
            return _componentInfos[i].point;
        }
    }
    EucCSSLayoutRunPoint ret = {0};
    return ret;
}

- (NSArray *)words
{
    NSUInteger wordsCount = _wordsCount;
    NSMutableArray *words = [NSMutableArray arrayWithCapacity:wordsCount];
    
    for(NSUInteger i = 0; i < wordsCount; ++i) {
        [words addObject:_componentInfos[_wordToComponent[i + 1]].contents.stringInfo.string];
    }
    
    return words;
}

- (NSArray *)attributeValuesForWordsForAttributeName:(NSString *)attributeName
{
    NSUInteger wordsCount = _wordsCount;
    NSMutableArray *attributeValues = [NSMutableArray arrayWithCapacity:wordsCount];
    
    EucCSSIntermediateDocumentNode *lastDocumentNode = nil;
    NSString *lastAttribute = nil;
    for(NSUInteger i = 0; i < wordsCount; ++i) {
        NSString *attribute = lastAttribute;
        EucCSSIntermediateDocumentNode *documentNode = _componentInfos[_wordToComponent[i + 1]].documentNode;
        if(documentNode != lastDocumentNode) {
            BOOL found = NO;
            EucCSSIntermediateDocumentNode *containingNode = documentNode;
            do {
                EucCSSIntermediateDocumentNode *containingNode = documentNode.parent;
                if([containingNode respondsToSelector:@selector(documentTreeNode)]) {
                    NSString *newAttribute =  [(id <EucCSSDocumentTreeNode>)[containingNode performSelector:@selector(documentTreeNode)] attributeWithName:attributeName];
                    if(newAttribute) {
                        if(![newAttribute isEqualToString:attribute]) {
                            lastAttribute = newAttribute;
                            attribute = newAttribute;
                        }
                        found = YES;
                    }
                }
            } while(containingNode && !found);
        
            lastDocumentNode = documentNode;
        }
        [attributeValues addObject:attribute ?: @""];
    }
    
    return attributeValues;    
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@, %@", [self class], [[self words] componentsJoinedByString:@" "]];
}

@end


