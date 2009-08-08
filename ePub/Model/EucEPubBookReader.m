//
//  EucEPubBookReader.m
//  Eucalyptus
//
//  Created by James Montgomerie on 26/07/2009.
//  Copyright 2009 James Montgomerie. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import "EucEPubBookReader.h"
#import "EucEPubBookParagraph.h"
#import "EucEPubStyleStore.h"
#import "EucBookTextStyle.h"
#import "EucEPubBook.h"
#import "THLog.h"
#import <sys/stat.h>

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
        _book = [book retain];
        _whitespaceAndNewlineCharacterSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] retain];
        _paragraphBuildingStyleStack = [[NSMutableArray alloc] init];
        _parser = XML_ParserCreate("UTF-8");
        
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
    [_paragraphBuildingStyleStack release];
    [_paragraphBuildingWords release];
    [_paragraphBuildingAttributes release];
    [_whitespaceAndNewlineCharacterSet release];
    [_xhtmlData release];
    if(_parser) {
        XML_ParserFree(_parser);
    }
    [_book release];
    free(_fileStartOffsetMap);
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
    } else {
        existingStyle = nil;
    }
    
    NSString *elementName = [NSString stringWithUTF8String:name];
    EucBookTextStyle *newStyle = [self->_styleStore styleForSelector:elementName fromStyle:existingStyle];

    for(int i = 0; atts[i]; i+=2) {
        if(strcmp("class", atts[i]) == 0) {
            const XML_Char *value = atts[i + 1];
            const XML_Char *endValue;
            while((endValue = strchr(value, ' '))) {
                if(endValue > value) {
                    NSString *class = [[NSString alloc] initWithBytes:value 
                                                               length:endValue - value
                                                             encoding:NSUTF8StringEncoding];
                    NSString *selector = [@"." stringByAppendingString:class];
                    newStyle = [self->_styleStore styleForSelector:selector fromStyle:newStyle];
                    [class release];
                }
                value = endValue + 1;
            }
            if(*value) {
                NSString *selector = [@"." stringByAppendingString:[NSString stringWithUTF8String:value]];
                newStyle = [self->_styleStore styleForSelector:selector fromStyle:newStyle];
            }
        } else if(strcmp("style", atts[i]) == 0) {
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
                UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfMappedFile:[pathUrl path]]];
                if(image) {
                    style.image = image;
                }
            }
            
            self->_paragraphBuildingCharactersEndedInWhitespace = YES;
        }
    } else if(strcmp("a", name) == 0) {
        NSMutableDictionary *anchorIDStore = self->_anchorIDStore;
        for(int i = 0; atts[i]; i+=2) {
            if(anchorIDStore && strcmp("id", atts[i]) == 0) {
                NSUInteger offset = self->_paragraphBuildingStartOffset + XML_GetCurrentByteIndex(self->_parser);
                NSString *path = [self->_packageRelativePath stringByAppendingFormat:@"#%@", [NSString stringWithUTF8String:atts[i+1]]];
                [anchorIDStore setObject:[NSNumber numberWithInteger:offset]
                                  forKey:path];
            }
            if(strcmp("href", atts[i]) == 0) {
                // Build an "internal:" link that points towards the book-
                // relative path that this anchor links to.
                NSString *hyperlink = nil;
                NSURL *hrefUrl = [NSURL URLWithString:[NSString stringWithUTF8String:atts[i+1]] relativeToURL:self->_baseURL];
                if([hrefUrl isFileURL]) {
                    NSString *bookHref = [[[hrefUrl path] stringByReplacingOccurrencesOfString:self->_book.path
                                                                                    withString:@""] retain];
                    NSString *fragment = [hrefUrl fragment];
                    if(fragment.length) {
                        bookHref = [bookHref stringByAppendingFormat:@"#%@", fragment]; 
                    }
                    hyperlink = [@"internal:" stringByAppendingString:bookHref];
                } else {
                    hyperlink = [hrefUrl absoluteString];
                }
                EucBookTextStyle *style = [self->_paragraphBuildingStyleStack lastObject];
                style = [style copy];
                [style setHyperlink:hyperlink];
                [self->_paragraphBuildingStyleStack removeLastObject];
                [self->_paragraphBuildingStyleStack addObject:style];
                [style release];                    
            }
        }
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

    const XML_Char *cursor = chars;
    const XML_Char *limit = chars + len;
    const XML_Char *wordStartsAt = NULL;
    while(cursor < limit) {
        if([self->_whitespaceAndNewlineCharacterSet characterIsMember:*cursor]) {
            if(wordStartsAt) {
                NSString *string = [[NSString alloc] initWithBytes:wordStartsAt 
                                                            length:cursor - wordStartsAt
                                                          encoding:NSUTF8StringEncoding];
                [self->_paragraphBuildingWords addObject:string];
                [string release];
                [self->_paragraphBuildingAttributes addObject:style];
                wordStartsAt = NULL;
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
        [self->_paragraphBuildingWords addObject:string];
        [string release];
        [self->_paragraphBuildingAttributes addObject:style];
        wordStartsAt = NULL;
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
    
    [_baseURL release];
    _baseURL = [[NSURL fileURLWithPath:path isDirectory:NO] retain];

    [_packageRelativePath release];
    _packageRelativePath = [[[_baseURL path] stringByReplacingOccurrencesOfString:[_book path]
                                                                       withString:@""] retain];
    if(_anchorIDStore) {
        [_anchorIDStore setObject:[NSNumber numberWithInteger:_fileStartOffsetMap[index]]
                           forKey:_packageRelativePath];        
    }
    
    [_styleStore release];
    _styleStore = [[EucEPubStyleStore alloc] init];
    [_styleStore addStylesFromCSSFile:[[NSBundle mainBundle] pathForResource:@"EPubDefault" ofType:@"css"]];
    
    [_xhtmlData release];
    _xhtmlData = [[NSData alloc] initWithContentsOfMappedFile:path];
    _startOffset = [self _parseHeader]; 
    
    _currentFileIndex = index;
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
    
    if(YES || offset < maxOffset) {
        [self _resetParserForParagraphParsing];
        
        _paragraphBuildingWords = [[NSMutableArray alloc] init];
        _paragraphBuildingAttributes = [[NSMutableArray alloc] init];
        self->_paragraphBuildingCharactersEndedInWhitespace = YES;

        size_t inFileOffset = offset - _fileStartOffsetMap[_currentFileIndex];
        if(inFileOffset < _startOffset) {
            inFileOffset = _startOffset;
            offset = inFileOffset + _fileStartOffsetMap[_currentFileIndex];
        }
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

        [_paragraphBuildingStyleStack removeAllObjects];

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
    NSLog(@"ANCHOR STORE: %@", _anchorIDStore);
    [_anchorIDStore writeToFile:[path stringByAppendingPathComponent:@"chapterOffsets.plist"] atomically:YES];
}

@end