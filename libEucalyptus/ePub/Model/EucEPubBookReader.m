//
//  EucEPubBookReader.m
//  libEucalyptus
//
//  Created by James Montgomerie on 26/07/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import "EucEPubBookReader.h"
#import "EucEPubBookParagraph.h"
#import "EucEPubStyleStore.h"
#import "EucBookTextStyle.h"
#import "EucEPubBook.h"
#import "THLog.h"
#import "THNSStringAdditions.h"
#import <sys/stat.h>

#define kMaxCachedFiles 3

@interface _CachedXHTMLFileInformation : NSObject {
    NSData *xhtmlData;
    NSURL *baseURL;
    NSString *packageRelativePath;
    int32_t startOffset;
    EucEPubStyleStore *styleStore;
}
@property (nonatomic, retain) NSData *xhtmlData;
@property (nonatomic, retain) NSURL *baseURL;
@property (nonatomic, retain) NSString *packageRelativePath;
@property (nonatomic, assign) int32_t startOffset;
@property (nonatomic, retain) EucEPubStyleStore *styleStore;
@end

@implementation _CachedXHTMLFileInformation
@synthesize xhtmlData;
@synthesize baseURL;
@synthesize packageRelativePath;
@synthesize startOffset;
@synthesize styleStore;

- (void)dealloc
{
    [xhtmlData release];
    [baseURL release];
    [packageRelativePath release];
    [styleStore release];
    [super dealloc];
}

@end


NSDictionary *sXHTMLEntityMap = nil;

@interface EucEPubBookReader ()
- (size_t)_parseHeader;
- (void)_resetParserForParagraphParsing;

- (void)_setCurrentFileIndex:(NSUInteger)index;
@end

@implementation EucEPubBookReader

- (id<EucBook>)book
{
    return _book;
}

+ (void)initialize
{
    sXHTMLEntityMap = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"XHTMLEntityMap" ofType:@"plist"]];
}

- (id)initWithBook:(id<EucBook>)anyBook
{
    NSParameterAssert([anyBook isKindOfClass:[EucEPubBook class]]);
    EucEPubBook *book = (EucEPubBook *)anyBook;
    
    if((self == [super init])) {
        _book = book;//[book retain];
        _whitespaceAndNewlineCharacterSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] retain];
        
        _parser = XML_ParserCreate("UTF-8");
        
        _xHTMLfileCache = [[NSMutableArray alloc] initWithCapacity:kMaxCachedFiles];
        
        NSArray *files = book.spineFiles; 
        NSUInteger filesCount = files.count;
        _fileStartOffsetMap = malloc(sizeof(size_t) * (filesCount + 1));
        size_t totalOffset = 0;
        _fileStartOffsetMapCount = 0;
        _fileStartOffsetMap[_fileStartOffsetMapCount++] = totalOffset;
        while(_fileStartOffsetMapCount < filesCount + 1) {
            struct stat statResult;
            if(stat([[files objectAtIndex:_fileStartOffsetMapCount - 1] fileSystemRepresentation], &statResult) == 0) {
                totalOffset += statResult.st_size;
                _fileStartOffsetMap[_fileStartOffsetMapCount++] = totalOffset;
            } else {
                [self release];
                return nil;
            }
        }
        
        _currentFileIndex = -1;
    }
    return self;
}

- (void)dealloc
{
    [_baseURL release];
    [_packageRelativePath release];
    [_styleStore release];
    [_paragraphBuildingWords release];
    [_paragraphBuildingAttributes release];
    [_whitespaceAndNewlineCharacterSet release];
    [_xhtmlData release];
    if(_parser) {
        XML_ParserFree(_parser);
    }
    //[_book release];
    free(_fileStartOffsetMap);
    [_xHTMLfileCache release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark Header Parsing

static void headerParsingStartElementHandler(void *ctx, const XML_Char *name, const XML_Char **atts) 
{
    EucEPubBookReader *self = (EucEPubBookReader *)ctx;
    
    if(strcmp("link", name) == 0) {
        const char *rel = NULL;
        const char *href = NULL;
        const char *type = NULL;
        for(int i = 0; atts[i]; i+=2) {
            if(strcmp("rel", atts[i]) == 0) {
                rel = atts[i + 1];
            }
            if(strcmp("href", atts[i]) == 0) {
                href = atts[i + 1];
            }
            if(strcmp("type", atts[i]) == 0) {
                type = atts[i + 1];
            }
        }
        if(rel && href && type) {
            if(strcasecmp(rel, "stylesheet") == 0 && 
               (strcasecmp(type, "text/css") == 0 || strcasecmp(type, "text/x-oeb1-css") == 0)) {
                NSURL *pathUrl = [NSURL URLWithString:[NSString stringWithUTF8String:href] relativeToURL:self->_baseURL];
                if([pathUrl isFileURL]) {
                    [self->_styleStore addStylesFromCSSFile:[pathUrl path]];
                }
            }
        }
    } else if(strcmp("body", name) == 0) {
        XML_StopParser(self->_parser, XML_FALSE); 
    }
}    

- (size_t)_parseHeader
{
    XML_ParserReset(_parser, NULL);
    XML_UseForeignDTD(_parser, XML_TRUE);
    XML_SetStartElementHandler(_parser, headerParsingStartElementHandler);
    XML_SetUserData(_parser, (void *)self);    
    XML_Parse(_parser, [_xhtmlData bytes], [_xhtmlData length], XML_FALSE);
    
    return XML_GetCurrentByteIndex(_parser);
}

#pragma mark -
#pragma mark Paragraph Building


static void paragraphBuildingStartElementHandler(void *ctx, const XML_Char *name, const XML_Char **atts) 
{
    EucEPubBookReader *self = (EucEPubBookReader *)ctx;
    
    EucBookTextStyle *existingStyle;
    if(self->_paragraphBuildingStyleStack.count) {
        existingStyle = [self->_paragraphBuildingStyleStack lastObject];
        if(strcmp("p", name) == 0 || strcmp("div", name) == 0) {
            THWarn(@"Nested <%s> tag encountered in %@ - not fully supported.", name, self->_baseURL, (long)(self->_paragraphBuildingStartOffset + XML_GetCurrentByteIndex(self->_parser))); 
        }        
    } else {
        existingStyle = nil;
    }
    
    NSString *elementName = [NSString stringWithUTF8String:name];
    EucBookTextStyle *newStyle = [self->_styleStore styleForSelector:elementName fromStyle:existingStyle];
    
    for(int i = 0; atts[i]; i+=2) {
        if(strcmp("class", atts[i]) == 0 || strcmp("id", atts[i]) == 0) {
            const XML_Char *value = atts[i + 1];
            const XML_Char *endValue;
            
            NSString *prepend = (atts[i][0] == 'c' ? @"." : @"#");
            
            while((endValue = strchr(value, ' '))) {
                if(endValue > value) {
                    NSString *class = [[NSString alloc] initWithBytes:value 
                                                               length:endValue - value
                                                             encoding:NSUTF8StringEncoding];
                    NSString *selector = [prepend stringByAppendingString:class];
                    newStyle = [self->_styleStore styleForSelector:selector fromStyle:newStyle];
                    [class release];
                }
                value = endValue + 1;
            }
            if(*value) {
                NSString *selector = [prepend stringByAppendingString:[NSString stringWithUTF8String:value]];
                newStyle = [self->_styleStore styleForSelector:selector fromStyle:newStyle];
            }

            if(self->_anchorIDStore && atts[i][0] == 'i') { // Store the offset of this tag with an id so that we can use links to it.
                NSUInteger offset = self->_paragraphBuildingStartOffset + XML_GetCurrentByteIndex(self->_parser);
                NSString *path = [self->_packageRelativePath stringByAppendingFormat:@"#%@", [NSString stringWithUTF8String:atts[i+1]]];
                [self->_anchorIDStore setObject:[NSNumber numberWithInteger:offset]
                                         forKey:path];
            }
        } else if(strcmp("style", atts[i]) == 0 && atts[i+1][0] != '\0') {
            if(!newStyle) {
                newStyle = [[[EucBookTextStyle alloc] init] autorelease];
            }
            newStyle = [self->_styleStore styleWithInlineStyleDeclaration:(char *)atts[i+1] fromStyle:newStyle];
        }      
    }
    
    if(!newStyle) {
        newStyle = [[[EucBookTextStyle alloc] init] autorelease];
    }
    [self->_paragraphBuildingStyleStack addObject:newStyle];
    
    if(strcmp("br", name) == 0) {
        if(self->_paragraphBuildingAttributes.count) {
            EucBookTextStyle *style = [self->_paragraphBuildingAttributes lastObject];
            style = [style styleBySettingFlag:EucBookTextStyleFlagZeroSpace];
            [self->_paragraphBuildingAttributes removeLastObject];
            [self->_paragraphBuildingAttributes addObject:style];
        }
        EucBookTextStyle *style = [self->_paragraphBuildingStyleStack lastObject];
        style = [style styleBySettingFlag:EucBookTextStyleFlagZeroSpace | EucBookTextStyleFlagHardBreak];
        [self->_paragraphBuildingWords addObject:@""];
        [self->_paragraphBuildingAttributes addObject:style];
        self->_paragraphBuildingCharactersEndedInWhitespace = YES;
    } else if(strcmp("img", name) == 0) {
        const XML_Char *width = NULL;
        const XML_Char *height = NULL;
        const XML_Char *src = NULL;
        for(int i = 0; atts[i]; i+=2) {
            if(strcmp("src", atts[i]) == 0) {
                src = atts[i+1];
            }
            if(strcmp("width", atts[i]) == 0) {
                width = atts[i+1];
            }
            if(strcmp("height", atts[i]) == 0) {
                height = atts[i+1];
            }
        }
        if(src) {
            EucBookTextStyle *style = [self->_paragraphBuildingStyleStack lastObject];
            if(width || height) {
                EucBookTextStyle *newStyle = [style copy];
                if(width) {
                    [newStyle setStyle:@"width" to:[NSString stringWithFormat:@"%spx", width]];
                }
                if(height) {
                    [newStyle setStyle:@"height" to:[NSString stringWithFormat:@"%spx", height]];
                }    
                
                // The top of the stack contained ths style constructed above 
                // for /this tag/, so we should replace it.
                [self->_paragraphBuildingStyleStack removeLastObject];
                [self->_paragraphBuildingStyleStack addObject:newStyle];
                [newStyle release];
                style = newStyle;
            }
            NSString *srcRelativePath = [NSString stringWithUTF8String:src];
            [self->_paragraphBuildingWords addObject:srcRelativePath];
            [self->_paragraphBuildingAttributes addObject:style];
            
            NSURL *pathUrl = [NSURL URLWithString:srcRelativePath relativeToURL:self->_baseURL];
            if([pathUrl isFileURL]) {
                UIImage *image = [UIImage imageWithData:[self->_book dataForFileAtURL:pathUrl]];
                if(image) {
                    style.image = image;
                }
            }
            
            self->_paragraphBuildingCharactersEndedInWhitespace = YES;
        }
    } else if(strcmp("a", name) == 0) {
        EucBookTextStyle *style = [self->_paragraphBuildingStyleStack lastObject];
        style = [style copy];

        for(int i = 0; atts[i]; i+=2) {
            if(strcmp("href", atts[i]) == 0) {
                // Build an "internal:" link that points towards the book-
                // relative path that this anchor links to.
                NSString *hyperlink = nil;
                NSURL *hrefUrl = [NSURL URLWithString:[NSString stringWithUTF8String:atts[i+1]] relativeToURL:self->_baseURL];
                if([hrefUrl isFileURL]) {
                    NSString *bookHref = [[hrefUrl path] stringByReplacingOccurrencesOfString:self->_book.path
                                                                                    withString:@""];
                    NSString *fragment = [hrefUrl fragment];
                    if(fragment.length) {
                        bookHref = [bookHref stringByAppendingFormat:@"#%@", fragment]; 
                    }
                    if([self->_book hasByteOffsetForUuid:bookHref]) {
                        // If this is an internal link, replace it with an 
                        // "internal" href.
                        hyperlink = [@"internal:" stringByAppendingString:bookHref];
                    }
                } 
                if(!hyperlink) {
                    hyperlink = [hrefUrl absoluteString];
                }
                [style setAttribute:@"href" to:hyperlink];
            } else {
                [style setAttribute:[NSString stringWithUTF8String:atts[i]] to:[NSString stringWithUTF8String:atts[i+1]]];
            }
        }
        
        [self->_paragraphBuildingStyleStack removeLastObject];
        [self->_paragraphBuildingStyleStack addObject:style];
        [style release];                            
    }
}    

static void paragraphBuildingEndElementHandler(void *ctx, const XML_Char *name) 
{
    EucEPubBookReader *self = (EucEPubBookReader *)ctx;
        
    if(self->_paragraphBuildingStyleStack.count == 1) {
        XML_StopParser(self->_parser, XML_FALSE);
    } else {
        [self->_paragraphBuildingStyleStack removeLastObject];
    }
}

static void paragraphBuildingCharactersHandler(void *ctx, const XML_Char *chars, int len) 
{
    EucEPubBookReader *self = (EucEPubBookReader *)ctx;
    
    if(!self->_paragraphBuildingCharactersEndedInWhitespace) {
        if(![self->_whitespaceAndNewlineCharacterSet characterIsMember:*chars]) {
            EucBookTextStyle *style = [self->_paragraphBuildingAttributes lastObject];
            style = [style styleBySettingFlag:EucBookTextStyleFlagNonBreaking|EucBookTextStyleFlagZeroSpace];
            [self->_paragraphBuildingAttributes removeLastObject];
            [self->_paragraphBuildingAttributes addObject:style];
        }
    }
    
    EucBookTextStyle *style = [self->_paragraphBuildingStyleStack lastObject];

    // Break up the text into individual words, and store.
    const XML_Char *cursor = chars;
    const XML_Char *limit = chars + len;
    const XML_Char *wordStartsAt = NULL;
    BOOL smartQuoteWord = NO;
    while(cursor < limit) {
        XML_Char ch = *cursor;
        if(ch == '"' || ch == '\'') {
            smartQuoteWord = YES;
        }
        if([self->_whitespaceAndNewlineCharacterSet characterIsMember:*cursor]) {
            if(wordStartsAt) {
                NSString *string = [[NSString alloc] initWithBytes:wordStartsAt 
                                                            length:cursor - wordStartsAt
                                                          encoding:NSUTF8StringEncoding];
                [self->_paragraphBuildingWords addObject:smartQuoteWord ? [string stringWithSmartQuotes] : string];
                [string release];
                [self->_paragraphBuildingAttributes addObject:style];
                wordStartsAt = NULL;
                smartQuoteWord = NO;
            }
        } else {
            if(!wordStartsAt) {
                wordStartsAt = cursor;
            }
        }
        ++cursor;
    }
    if(wordStartsAt) {
        NSString *string = [[NSString alloc] initWithBytes:wordStartsAt 
                                                    length:cursor - wordStartsAt
                                                  encoding:NSUTF8StringEncoding];
        [self->_paragraphBuildingWords addObject:smartQuoteWord ? [string stringWithSmartQuotes] : string];
        [string release];
        [self->_paragraphBuildingAttributes addObject:style];
        wordStartsAt = NULL;
        smartQuoteWord = NO;
    }    
    
    self->_paragraphBuildingCharactersEndedInWhitespace = [self->_whitespaceAndNewlineCharacterSet characterIsMember:*(cursor - 1)];
}

void paragraphBuildingSkippedEntityHandler(void *ctx, const XML_Char *entityName, int is_parameter_entity)
{
    EucEPubBookReader *self = (EucEPubBookReader *)ctx;

    if(!self->_paragraphBuildingCharactersEndedInWhitespace) {
        EucBookTextStyle *style = [self->_paragraphBuildingAttributes lastObject];
        style = [style styleBySettingFlag:EucBookTextStyleFlagNonBreaking|EucBookTextStyleFlagZeroSpace];
        [self->_paragraphBuildingAttributes removeLastObject];
        [self->_paragraphBuildingAttributes addObject:style];
    }    
    self->_paragraphBuildingCharactersEndedInWhitespace = NO;

    UniChar translatedCharacter = 0;
    if(*entityName == '#') {
        const XML_Char *cursor = entityName+1;
        while(*cursor && isdigit(*cursor)) {
            translatedCharacter *= 10;
            translatedCharacter += (*cursor - '0');
        }
    } else {
        NSString *string = [[NSString alloc] initWithUTF8String:entityName];
        translatedCharacter = [[sXHTMLEntityMap objectForKey:string] unsignedShortValue];
        [string release];
    }
    
    NSString *translated;
    if(translatedCharacter) {
        translated = [NSString stringWithCharacters:&translatedCharacter length:1];
    } else {
        NSString *string = [[NSString alloc] initWithUTF8String:entityName];
        translated = [NSString stringWithFormat:@"&%@;", string];
        [string release];
    }
        
    [self->_paragraphBuildingWords addObject:translated];
    [self->_paragraphBuildingAttributes addObject:[self->_paragraphBuildingStyleStack lastObject]];
}

- (void)_resetParserForParagraphParsing
{
    XML_ParserReset(_parser, NULL);
    XML_UseForeignDTD(_parser, XML_TRUE);
    XML_SetElementHandler(_parser, paragraphBuildingStartElementHandler, paragraphBuildingEndElementHandler);
    XML_SetCharacterDataHandler(_parser, paragraphBuildingCharactersHandler);
    XML_SetSkippedEntityHandler(_parser, paragraphBuildingSkippedEntityHandler);
    XML_SetUserData(_parser, (void *)self);    
}

- (void)_setCurrentFileIndex:(NSUInteger)index
{
    NSString *path = [_book.spineFiles objectAtIndex:index];
    NSURL *baseURL = [NSURL fileURLWithPath:path isDirectory:NO];
    
    // Opening a file and parsing the header is quite expensive, slowing
    // down page resize and turning delays unacceptably, especially on a
    // 1st gen iPhone.  To combat this, we cache the last few files opened,
    // and the information gleaned from parsing the headers.
    
    // Look to see if we already have this file's information cached.
    _CachedXHTMLFileInformation *cachedFileInfo = nil;
    for(_CachedXHTMLFileInformation *potentialCachedFileInfo in _xHTMLfileCache) {
        if([potentialCachedFileInfo.baseURL isEqual:baseURL]) {
            cachedFileInfo = potentialCachedFileInfo;
            break;
        }
    }
    
    if(cachedFileInfo) {
        // Re-use the information from the cache.
        [cachedFileInfo retain];
        
        // Remove the file info from the cache - we'll re store it in the
        // 'most recent' position after this 'if', before we return.
        [_xHTMLfileCache removeObject:cachedFileInfo]; 
        
        [_baseURL release];
        _baseURL = [cachedFileInfo.baseURL retain];
        [_xhtmlData release];
        _xhtmlData = [cachedFileInfo.xhtmlData retain];
        [_packageRelativePath release];
        _packageRelativePath = [cachedFileInfo.packageRelativePath retain];
        _startOffset = cachedFileInfo.startOffset;
        [_styleStore release];
        _styleStore = [cachedFileInfo.styleStore retain];            
    } else {
        // Open and parse the header of this file.
        [_baseURL release];
        _baseURL = [baseURL retain];
        
        [_xhtmlData release];
        _xhtmlData = [[NSData dataWithContentsOfMappedFile:path] retain];
        
        [_packageRelativePath release];
        _packageRelativePath = [[[baseURL path] stringByReplacingOccurrencesOfString:[_book path]
                                                                          withString:@""] retain];
        [_styleStore release];
        _styleStore = [[EucEPubStyleStore alloc] init];
        [_styleStore addStylesFromCSSFile:[[NSBundle mainBundle] pathForResource:@"EPubDefault" ofType:@"css"]];
        
        _startOffset = [self _parseHeader]; 
        
        // Make the object representing this file and the info we've parsed to
        // store in the cache.
        cachedFileInfo = [[_CachedXHTMLFileInformation alloc] init];
        cachedFileInfo.baseURL = _baseURL;
        cachedFileInfo.xhtmlData = _xhtmlData;
        cachedFileInfo.packageRelativePath = _packageRelativePath;
        cachedFileInfo.startOffset = _startOffset;
        cachedFileInfo.styleStore = _styleStore;
    }
    
    
    // Remove the least recently used cache item if the cache is getting too
    // large, and cache this file's info.
    if(_xHTMLfileCache.count > kMaxCachedFiles) {
        [_xHTMLfileCache removeObjectAtIndex:0];
    }
    [_xHTMLfileCache addObject:cachedFileInfo];
    
    [cachedFileInfo release];
    
    
    // Update our state.
    _currentFileIndex = index;
    
    if(_anchorIDStore) {
        [_anchorIDStore setObject:[NSNumber numberWithInteger:_fileStartOffsetMap[index]]
                           forKey:_packageRelativePath];        
    }    
}

- (EucEPubBookParagraph *)paragraphAtOffset:(size_t)offset maxOffset:(size_t)maxOffset
{
    EucEPubBookParagraph *ret = nil;
    
    NSUInteger fileContainingOffset = 0;
    while(fileContainingOffset < _fileStartOffsetMapCount-1 && 
          _fileStartOffsetMap[fileContainingOffset+1] <= offset) {
        ++fileContainingOffset;
    }

    if(fileContainingOffset != _currentFileIndex) {
        if(fileContainingOffset < _fileStartOffsetMapCount - 1) {
            [self _setCurrentFileIndex:fileContainingOffset];
        } else {
            return nil;
        }
    }
    
    if(offset == -1 || offset < maxOffset) {
        size_t inFileOffset = offset - _fileStartOffsetMap[_currentFileIndex];
        if(inFileOffset < _startOffset) {
            inFileOffset = _startOffset;
            offset = inFileOffset + _fileStartOffsetMap[_currentFileIndex];
        }
        
        [self _resetParserForParagraphParsing];
        
        // If this get's any mre complex, might be nice to build a paragraph
        // parsing class, or even just a struct to store these in, and not have
        // the paragraph parser access these ivars directly.
        _paragraphBuildingWords = [[NSMutableArray alloc] init];
        _paragraphBuildingAttributes = [[NSMutableArray alloc] init];
        _paragraphBuildingStyleStack = [[NSMutableArray alloc] init];
        self->_paragraphBuildingCharactersEndedInWhitespace = YES;
        
        _paragraphBuildingStartOffset = offset;
        XML_Parse(_parser, [_xhtmlData bytes] + inFileOffset, [_xhtmlData length] - inFileOffset, XML_FALSE);

        if(_paragraphBuildingStyleStack.count) {
            size_t endOffset = offset + XML_GetCurrentByteIndex(_parser);
            ret =  [[EucEPubBookParagraph alloc] initWithWords:_paragraphBuildingWords
                                      wordFormattingAttributes:_paragraphBuildingAttributes
                                                    byteOffset:offset
                                       nextParagraphByteOffset:endOffset
                                                   globalStyle:[_paragraphBuildingStyleStack objectAtIndex:0]];
        }        
            
        [_paragraphBuildingWords release];
        _paragraphBuildingWords = nil;
        [_paragraphBuildingAttributes release];
        _paragraphBuildingAttributes = nil;
        [_paragraphBuildingStyleStack release];
        _paragraphBuildingStyleStack = nil;

        if(!ret && _currentFileIndex < _fileStartOffsetMapCount - 1) {
            return [self paragraphAtOffset:_fileStartOffsetMap[fileContainingOffset+1] maxOffset:maxOffset];
        }
    }
    return [ret autorelease];
}

- (BOOL)shouldCollectPaginationData
{
    return _anchorIDStore != nil;
}

- (void)setShouldCollectPaginationData:(BOOL)collect
{
    if(collect) {
        [_anchorIDStore release];
        _anchorIDStore = [[NSMutableDictionary alloc] init];
    } else {
        [_anchorIDStore release];
        _anchorIDStore = nil;
    }
}

- (void)savePaginationDataToDirectoryAt:(NSString *)path
{
    [_anchorIDStore writeToFile:[path stringByAppendingPathComponent:@"chapterOffsets.plist"] atomically:YES];
}

@end