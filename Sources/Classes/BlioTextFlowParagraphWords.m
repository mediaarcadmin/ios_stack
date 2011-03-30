//
//  BlioTextFlowParagraphWords.m
//  BlioApp
//
//  Created by James Montgomerie on 18/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//


#import "BlioTextFlowParagraphWords.h"
#import "BlioTextFlowParagraph.h"
#import "BlioTextFlow.h"
#import "BlioBookmark.h"
#import "BlioTextFlowPositionedWord.h"

@interface BlioTextFlowParagraphWords ()

@property (nonatomic, assign, readonly) uint32_t key;

@end

@implementation BlioTextFlowParagraphWords

@synthesize key = _key;
@synthesize ranges = _ranges;

- (id)initWithTextFlow:(BlioTextFlow *)textFlow
             paragraph:(BlioTextFlowParagraph *)paragraph 
                ranges:(NSArray *)ranges
                   key:(uint32_t)key
{
    if((self = [super init])) {
        _textFlow = textFlow;
        _paragraph = paragraph;
        _ranges = [ranges retain];
        _key = key;
    }
    return self;
}


- (void)dealloc
{
    [_wordStrings release];
    [_ranges release];
    
    [super dealloc];
}

- (EucCSSDocumentTreeNodeKind)kind
{
    return EucCSSDocumentTreeNodeKindText;
}

- (NSString *)name
{
    return nil;
}

- (uint32_t)childCount
{
    return 0;
}

- (id<EucCSSDocumentTreeNode>)firstChild
{
    return nil;
}

- (id<EucCSSDocumentTreeNode>)previousSibling
{
    return nil;
}

- (id<EucCSSDocumentTreeNode>)nextSibling
{
    return nil;
}

- (id<EucCSSDocumentTreeNode>)parent
{
    return _paragraph;
}

- (NSString *)attributeWithName:(NSString *)attributeName
{
    return nil;
}

- (BlioBookmarkPoint *)wordOffsetToBookmarkPoint:(uint32_t)wordOffset
{
    NSArray *words;
    if(_ranges.count == 1) {
        words = [_textFlow wordsForBookmarkRange:_ranges.lastObject];
    } else {
        words = [NSMutableArray array];
        for(BlioBookmarkRange *range in _ranges) {
            [(NSMutableArray *)words addObjectsFromArray:[_textFlow wordsForBookmarkRange:range]];
            if(words.count > wordOffset) {
                break;
            }
        }    
    }
    
    BlioTextFlowPositionedWord *word = [words objectAtIndex:wordOffset];
    BlioBookmarkPoint *point = [[BlioBookmarkPoint alloc] init];
    
    point.layoutPage = [BlioTextFlowBlock pageIndexForBlockID:word.blockID];
    point.blockOffset = [BlioTextFlowBlock blockIndexForBlockID:word.blockID];
    point.wordOffset = word.wordIndex;
    
    return [point autorelease];
}

- (NSArray *)preprocessedWordStrings
{
    return [self wordStrings];
}

- (NSArray *)words
{
    if(_ranges.count == 1) {
        return [_textFlow wordsForBookmarkRange:_ranges.lastObject];
    } else {
        NSMutableArray *words = [NSMutableArray array];
        for(BlioBookmarkRange *range in _ranges) {
            [words addObjectsFromArray:[_textFlow wordsForBookmarkRange:range]];
        }    
        return words;
    }
}

- (NSArray *)wordStrings
{
    if(!_wordStrings) {
        if(_ranges.count == 1) {
            _wordStrings = [[_textFlow wordStringsForBookmarkRange:_ranges.lastObject] retain];
        } else {
            NSMutableArray *words = [NSMutableArray array];
            for(BlioBookmarkRange *range in _ranges) {
                [words addObjectsFromArray:[_textFlow wordStringsForBookmarkRange:range]];
            }    
            _wordStrings = [words retain];
        }
    }
    return _wordStrings;
}

- (BOOL)getCharacterContents:(const char **)contents length:(size_t *)length
{
    NSString *string = [[self wordStrings] componentsJoinedByString:@" "];
    *contents = [string UTF8String];
    *length = strlen(*contents);
    return YES;
}

- (BOOL)isImageNode
{
    return NO;
}

- (NSString *)imageSourceURLString
{
    return nil;
}

- (BOOL)isHyperlinkNode
{
    return NO;
}

- (NSString *)hyperlinkURLString
{
    return nil;
}

- (NSString *)CSSID
{
    return nil;
}

- (NSString *)CSSClasses
{
    return nil;
}

- (NSString *)inlineStyle
{
    return nil;
}

@end
