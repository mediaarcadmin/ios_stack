//
//  EucEPubBook.m
//  Eucalyptus
//
//  Created by James Montgomerie on 28/07/2009.
//  Copyright 2009 James Montgomerie. All rights reserved.
//

#import "THLog.h"
#import "EucEPubBook.h"
#import "EucBookPageIndexPoint.h"
#import "EucEPubBookReader.h"
#import "EucBookSection.h"
#import "THPair.h"
#import "expat.h"

#import <fcntl.h>
#import <sys/stat.h>
#import <sys/mman.h>

@implementation EucEPubBook

@synthesize sections = _sections;

#pragma mark -
#pragma mark container.xml parsing

static void containerXMLParsingStartElementHandler(void *ctx, const XML_Char *name, const XML_Char **atts) 
{
    EucEPubBook *self = (EucEPubBook *)ctx;
    
    if(strcmp("rootfile", name) == 0) {
        for(int i = 0; atts[i]; i+=2) {
            if(strcmp("full-path", atts[i]) == 0) {
                NSString *fullPath = [[NSString alloc] initWithUTF8String:atts[i+1]];
                [self->_contentURL release];
                self->_contentURL = [[NSURL URLWithString:fullPath relativeToURL:self->_root] retain];
                [fullPath release];
            }
        }
    }
}    

- (void)_parseContainerXml:(NSString *)path
{
    NSData *data = [[NSData alloc] initWithContentsOfMappedFile:path];
    XML_Parser parser = XML_ParserCreate("UTF-8");
    XML_SetStartElementHandler(parser, containerXMLParsingStartElementHandler);
    XML_SetUserData(parser, (void *)self);    
    XML_Parse(parser, [data bytes], [data length], XML_TRUE);
    XML_ParserFree(parser);
    [data release];
}

#pragma mark -
#pragma mark content.opf parsing

struct contentOpfParsingContext
{
    XML_Parser parser;
    EucEPubBook *self;
    BOOL inMetadata;
    BOOL inCreator;
    BOOL inTitle;
    BOOL inIdentifier;
    BOOL inSpine;
    
    BOOL inManifest;
    NSMutableDictionary *buildManifest;
    NSMutableArray *buildSpine;
};

static void contentOpfStartElementHandler(void *ctx, const XML_Char *name, const XML_Char **atts) 
{
    struct contentOpfParsingContext *context = (struct contentOpfParsingContext*)ctx;
    
    if(context->inMetadata) {
        if(strcmp("dc:title", name) == 0) {
            context->inTitle = YES;
        } else if(strcmp("dc:creator", name) == 0) {
            context->inCreator = YES;
        } else if(strcmp("dc:identifier", name) == 0) {
            context->inIdentifier = YES;
        }
        return;
    }    
    
    if(context->inManifest) {
        if(strcmp("item", name) == 0) {
            NSString *id = nil;
            NSString *href = nil;
            for(int i = 0; atts[i]; i+=2) {
                if(strcmp("id", atts[i]) == 0) {
                    id = [[NSString alloc] initWithUTF8String:atts[i+1]];
                } else if(strcmp("href", atts[i]) == 0) {
                    href = [[NSString alloc] initWithUTF8String:atts[i+1]];
                }
            }
            if(id && href) {
                [context->buildManifest setObject:href forKey:id];
            }
        }
        return;
    }
    
    if(context->inSpine) {
        if(strcmp("itemref", name) == 0) {
            for(int i = 0; atts[i]; i+=2) {
                if(strcmp("idref", atts[i]) == 0) {
                    [context->buildSpine addObject:[[NSString alloc] initWithUTF8String:atts[i+1]]];
                }   
            }
        }
    }
    
    if(strcmp("metadata", name) == 0) {
        context->inMetadata = YES;
    } else if(strcmp("manifest", name) == 0) {
        context->inManifest = YES;
    } else if(strcmp("spine", name) == 0) {
        for(int i = 0; atts[i]; i+=2) {
            if(strcmp("toc", atts[i]) == 0) {
                [context->self->_tocNcxId release];
                context->self->_tocNcxId  = [[NSString alloc] initWithUTF8String:atts[i+1]];
            }
        }      
        context->inSpine = YES;
    }
}    

static void contentOpfEndElementHandler(void *ctx, const XML_Char *name) 
{
    struct contentOpfParsingContext *context = (struct contentOpfParsingContext*)ctx;
    if(context->inMetadata) {
        if(context->inTitle && strcmp("dc:title", name) == 0) {
            context->inTitle = NO;
        } else if(context->inCreator && strcmp("dc:creator", name) == 0) {
            context->inCreator = NO;
        } else if(context->inIdentifier && strcmp("dc:identifier", name) == 0) {
            context->inIdentifier = NO;
        }
        if(strcmp("metadata", name) == 0) {
            context->inMetadata = NO;
        }
    } else if(context->inManifest) {
        if(strcmp("manifest", name) == 0) {
            context->inManifest = NO;
        }
    } else if(context->inSpine) {
        if(strcmp("spine", name) == 0) {
            context->inSpine = NO;
        }        
    }
}

static void contentOpfCharacterDataHandler(void *ctx, const XML_Char *chars, int len) 
{
    struct contentOpfParsingContext *context = (struct contentOpfParsingContext*)ctx;
    if(context->inMetadata &&
       (context->inTitle || context->inCreator || context->inIdentifier)) {
        NSString *string = [[NSString alloc] initWithBytes:chars 
                                                    length:len
                                                  encoding:NSUTF8StringEncoding];
        
        // The following is a bit messy...
        // Could rewrite using properties, in retrospect.
        if(context->inTitle) {
            if(!context->self->_title) {
                context->self->_title = [string retain];
            } else {
                NSString *newString = [context->self->_title stringByAppendingString:string];
                [context->self->_title release];
                context->self->_title = [newString retain];
            }
        } else if(context->inCreator) {
            if(!context->self->_author) {
                context->self->_author  = [string retain];
            } else {
                NSString *newString = [context->self->_author stringByAppendingString:string];
                [context->self->_author release];
                context->self->_author = [newString retain];
            }            
        } else if(context->inIdentifier) {
            if(!context->self->_etextNumber) {
                context->self->_etextNumber  = [string retain];
            } else {
                NSString *newString = [context->self->_etextNumber stringByAppendingString:string];
                [context->self->_etextNumber release];
                context->self->_etextNumber = [newString retain];
            }            
        }
        [string release];
    }
}

- (void)_parseContentOpf:(NSString *)path
{
    NSData *data = [[NSData alloc] initWithContentsOfMappedFile:path];
    XML_Parser parser = XML_ParserCreate("UTF-8");

    struct contentOpfParsingContext context = {0};
    context.parser = parser;
    context.self = self;
    context.buildManifest = [[NSMutableDictionary alloc] init];
    context.buildSpine = [[NSMutableArray alloc] init];
    
    XML_SetStartElementHandler(parser, contentOpfStartElementHandler);
    XML_SetEndElementHandler(parser, contentOpfEndElementHandler);
    XML_SetCharacterDataHandler(parser, contentOpfCharacterDataHandler);
    XML_SetUserData(parser, (void *)&context);    
    XML_Parse(parser, [data bytes], [data length], XML_TRUE);
    XML_ParserFree(parser);
    
    [_manifest release];
    _manifest = context.buildManifest;
    [_spine release];
    _spine = context.buildSpine;
    [data release];
}

#pragma mark -
#pragma mark toc.ncx parsing

struct tocNcxParsingContext
{
    XML_Parser parser;
    
    BOOL inNavMap;
    BOOL inNavPoint;
    BOOL inNavLabel;
    
    NSString *thisLabelText;
    NSString *thisLabelSrc;
    NSUInteger thisLabelPlayOrder;
    
    NSMutableDictionary *buildNavMap;
};

static void tocNcxStartElementHandler(void *ctx, const XML_Char *name, const XML_Char **atts)
{
    struct tocNcxParsingContext *context = (struct tocNcxParsingContext *)ctx;
    if(!context->inNavMap) {
        if(strcmp("navMap", name) == 0) {
            context->inNavMap = YES;
        }
    } else {
        if(!context->inNavPoint) {
            if(strcmp("navPoint", name) == 0) {
                context->inNavPoint = YES;
                for(int i = 0; atts[i]; i+=2) {
                    if(strcmp("playOrder", atts[i]) == 0) {
                        context->thisLabelPlayOrder = atoi(atts[i+1]);
                    }
                }
            }
        } else {
            if(!context->inNavLabel) {
                if(strcmp("navLabel", name) == 0) {
                    context->inNavLabel = YES;
                } else if(strcmp("content", name) == 0) {
                    for(int i = 0; atts[i]; i+=2) {
                        if(strcmp("src", atts[i]) == 0) {
                            context->thisLabelSrc = [[NSString stringWithUTF8String:atts[i+1]] retain];
                        }
                    }            
                }
            }
        }
    }
}

static void tocNcxEndElementHandler(void *ctx, const XML_Char *name)                     
{
    struct tocNcxParsingContext *context = (struct tocNcxParsingContext *)ctx;
    if(context->inNavMap) { 
        if(context->inNavPoint) {
            if(context->inNavLabel) {
                if(strcmp("navLabel", name) == 0) {
                    context->inNavLabel = NO;
                }
            } else if(strcmp("navPoint", name) == 0) {
                context->inNavPoint = NO;
                
                if(context->thisLabelSrc && context->thisLabelText) {
                    [context->buildNavMap setObject:[THPair pairWithFirst:context->thisLabelText second:context->thisLabelSrc]
                     forKey:[NSNumber numberWithUnsignedInteger:context->thisLabelPlayOrder]];
                }
                
                [context->thisLabelText release];
                context->thisLabelText = nil;
                [context->thisLabelSrc release];
                context->thisLabelSrc = nil;
                context->thisLabelPlayOrder = 0;                
            }
        } else if(strcmp("navMap", name) == 0) {
            context->inNavMap = NO;
        } 
    }
}

static void tocNcxCharacterDataHandler(void *ctx, const XML_Char *chars, int len) 
{
    struct tocNcxParsingContext *context = (struct tocNcxParsingContext *)ctx;
    
    if(context->inNavLabel) {
        NSString *text = [[NSString alloc] initWithBytes:chars length:len encoding:NSUTF8StringEncoding];
        if(context->thisLabelText && text.length) {
            NSString *newText = [context->thisLabelText stringByAppendingString:text];
            [context->thisLabelText release];
            [text release];
            context->thisLabelText = [newText retain];
        } else {
            context->thisLabelText = text;
        }
    }
}


- (void)_parseTocNcx:(NSString *)path
{
    if(_anchorPoints) {
        NSData *data = [[NSData alloc] initWithContentsOfMappedFile:path];
        XML_Parser parser = XML_ParserCreate("UTF-8");
        
        struct tocNcxParsingContext context = {0};
        context.parser = parser;
        context.buildNavMap = [[NSMutableDictionary alloc] init];
        
        XML_SetStartElementHandler(parser, tocNcxStartElementHandler);
        XML_SetEndElementHandler(parser, tocNcxEndElementHandler);
        XML_SetCharacterDataHandler(parser, tocNcxCharacterDataHandler);
        XML_SetUserData(parser, (void *)&context);    
        XML_Parse(parser, [data bytes], [data length], XML_TRUE);
        XML_ParserFree(parser);

        [data release];
        
        NSURL *baseUrl = [NSURL fileURLWithPath:path];
        
        NSMutableArray *sectionsBuild = [[NSMutableArray alloc] init];
        NSArray *orderedKeys = [[context.buildNavMap allKeys] sortedArrayUsingSelector:@selector(compare:)];
        for(id key in orderedKeys) {
            THPair *navPoint = [context.buildNavMap objectForKey:key];
            NSString *name = navPoint.first;
            NSString *src = navPoint.second;

            NSURL *srcUrl = [NSURL URLWithString:src relativeToURL:baseUrl];
            src = [[[srcUrl path] stringByReplacingOccurrencesOfString:_path
                                                            withString:@""] retain];
            NSString *fragment = [srcUrl fragment];
            if(fragment.length) {
                src = [src stringByAppendingFormat:@"#%@", fragment]; 
            }
            //NSLog(@"%@, %@",  srcUrl, src);
            NSNumber *location = [_anchorPoints objectForKey:src];
            if(location) {
                EucBookSection *newSection = [[EucBookSection alloc] init];
                [newSection setStartOffset:[location unsignedIntegerValue]];
                [newSection setKind:kBookSectionNondescript];
                [newSection setUuid:src];
                [newSection setProperty:name forKey:kBookSectionPropertyTitle];
                [sectionsBuild addObject:newSection];
            }
            [sectionsBuild sortUsingSelector:@selector(compare:)];
        }
        _sections = sectionsBuild;
        [context.buildNavMap release];
    }
}

#pragma mark -

- (id)initWithPath:(NSString *)path
{
    if((self = [super init])) {
        self.path = path;
        _root = [[NSURL fileURLWithPath:path] retain];
        
        _anchorPoints = [[NSDictionary dictionaryWithContentsOfFile:[path stringByAppendingPathComponent:@"chapterOffsets.plist"]] retain];
        
        [self _parseContainerXml:[path stringByAppendingPathComponent:@"META-INF/container.xml"]];
        
        if(!_contentURL) {
            THWarn(@"Couldn't find content root for book at %@", path);
            [self release];
            return nil;
        }
        
        [self _parseContentOpf:[_contentURL path]];
        
        if(!_etextNumber.length|| !_spine.count || !_manifest.count || !_tocNcxId || ![_manifest objectForKey:_tocNcxId]) {
            THWarn(@"Couldn't find toc.ncx location for %@", path);
            [self release];
            return nil;
        } 
        
        NSString *tocPath = [[NSURL URLWithString:[_manifest objectForKey:_tocNcxId] relativeToURL:_contentURL] path];
        [self _parseTocNcx:tocPath];
        
    }
    return self;
}

- (void)dealloc 
{    
    if(_currentPageIndexPointFD) {
        close(_currentPageIndexPointFD);
    }
    
    [_root release];
    [_contentURL release];
    [_tocNcxId release];
    [_anchorPoints release];
    [_manifest release];
    
    [super dealloc];
}

- (NSArray *)spineFiles
{
    NSMutableArray *files = [[NSMutableArray alloc] init];
    for(NSString *id in _spine) {
        NSString *relativePath = [_manifest objectForKey:id];
        NSURL *fileUrl = [NSURL URLWithString:relativePath relativeToURL:self->_contentURL];
        if([fileUrl isFileURL]) {
            NSString *path = [fileUrl path];
            if(path) {
                [files addObject:path];
            }
        }
    }
    return files;
}

- (id<EucBookReader>)reader
{
    return [[[EucEPubBookReader alloc] initWithBook:self] autorelease];
}

- (size_t)startOffset
{
    return 0;
}

- (EucBookPageIndexPoint *)currentPageIndexPoint
{
    if(_currentPageIndexPointFD) {
        lseek(_currentPageIndexPointFD, SEEK_SET, 0); 
    } else {
        NSString *indexPointsFolderPath;
        indexPointsFolderPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        indexPointsFolderPath = [indexPointsFolderPath stringByAppendingPathComponent:@"gs.ingsmadeoutofotherthin.th"];
        indexPointsFolderPath = [indexPointsFolderPath stringByAppendingPathComponent:@"bookPositions"];

        NSError *dirCreationError = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:indexPointsFolderPath
                                  withIntermediateDirectories:YES
                                                   attributes:NULL 
                                                        error:&dirCreationError];
        if(dirCreationError) {
            THWarn(@"Could not create directory at %@, error %@", indexPointsFolderPath, dirCreationError);
        } else {
            NSString *path = [indexPointsFolderPath stringByAppendingPathComponent:self.etextNumber];
            path = [path stringByAppendingPathExtension:@"currentIndexPoint"];

            _currentPageIndexPointFD = open([path fileSystemRepresentation], O_RDWR | O_CREAT, S_IRUSR | S_IWUSR);
            if(_currentPageIndexPointFD != -1) {
                struct stat statResult;
                if(fstat(_currentPageIndexPointFD, &statResult) != -1) {
                    if(statResult.st_size == 0) {
                        EucBookPageIndexPoint *cover = [[EucBookPageIndexPoint alloc] init];
                        [self setCurrentPageIndexPoint:cover];
                        return [cover autorelease]; 
                    }
                } else {
                    THWarn(@"Could not stat file at %@, error %d", path, errno);
                }
            } else {
                _currentPageIndexPointFD = 0;
                THWarn(@"Could not open file at %@, error %d", path, errno);
            }
        }
    }
    
    return [EucBookPageIndexPoint bookPageIndexPointFromOpenFD:_currentPageIndexPointFD];
}


- (void)setCurrentPageIndexPoint:(EucBookPageIndexPoint *)currentPage
{
    if(! _currentPageIndexPointFD) {
        [self currentPageIndexPoint]; // Will create a file if necessary.
    }
    lseek(_currentPageIndexPointFD, SEEK_SET, 0); 
    [currentPage writeToOpenFD:_currentPageIndexPointFD];
}

- (Class)pageLayoutControllerClass
{
    return NSClassFromString(@"EucEPubPageLayoutController");
}

- (EucBookSection *)sectionWithUuid:(NSString *)uuid
{
    for(EucBookSection *section in _sections) {
        if([section.uuid isEqualToString:uuid]) {
            return section;
        }
    }    
    return nil;    
}

- (NSUInteger)byteOffsetForUuid:(NSString *)uuid
{
    return [[_anchorPoints objectForKey:uuid] unsignedIntegerValue];    
}

- (EucBookSection *)topLevelSectionForByteOffset:(NSUInteger)byteOffset
{
    EucBookSection *section = [_sections objectAtIndex:0];
    for(EucBookSection *potentialSection in _sections) {
        if(potentialSection.startOffset <= byteOffset) {
            section = potentialSection;
        } else {
            break;
        }
    }
    return section;
}

- (EucBookSection *)previousTopLevelSectionForByteOffset:(NSUInteger)byteOffset
{
    for(EucBookSection *section in [_sections reverseObjectEnumerator]) {
        if(section.startOffset < byteOffset) {
            return section;
        }
    }
    return nil;
}

- (EucBookSection *)nextTopLevelSectionForByteOffset:(NSUInteger)byteOffset
{
    for(EucBookSection *section in _sections) {
        if(section.startOffset > byteOffset) {
            return section;
        }
    }
    return nil;
}

@end
