//
//  EucEPubBook.m
//  libEucalyptus
//
//  Created by James Montgomerie on 28/07/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import "THLog.h"
#import "EucEPubBook.h"
#import "EucBookPageIndex.h"
#import "EucFilteredBookPageIndex.h"
#import "EucBookPageIndexPoint.h"
#import "EucBookReader.h"
#import "EucEPubBookReader.h"
#import "EucBookParagraph.h"
#import "EucBookSection.h"
#import "THPair.h"
#import "expat.h"

#import <fcntl.h>
#import <sys/stat.h>
#import <sys/mman.h>

@interface EucEPubBook ()
@property (nonatomic, retain) NSDictionary *manifestOverrides;
@end

@implementation EucEPubBook

@synthesize sections = _sections;
@synthesize manifestOverrides = _manifestOverrides;

static inline const XML_Char* unqualifiedName(const XML_Char *name) {
    const XML_Char *offset = strrchr(name, ':');
    if(offset) {
        return offset + 1;
    } else {
        return name;
    }
}

#pragma mark -
#pragma mark container.xml parsing

static void containerXMLParsingStartElementHandler(void *ctx, const XML_Char *name, const XML_Char **atts) 
{
    name = unqualifiedName(name);

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
    BOOL inMeta;
    BOOL inSpine;
    
    BOOL inManifest;
    NSMutableDictionary *buildMeta;
    NSMutableDictionary *buildManifest;
    NSMutableArray *buildSpine;
};

static void contentOpfStartElementHandler(void *ctx, const XML_Char *name, const XML_Char **atts) 
{
    name = unqualifiedName(name);

    struct contentOpfParsingContext *context = (struct contentOpfParsingContext*)ctx;
    
    if(context->inMetadata) {
        if(strcmp("title", name) == 0) {
            context->inTitle = YES;
        } else if(strcmp("creator", name) == 0) {
            context->inCreator = YES;
        } else if(strcmp("identifier", name) == 0) {
            context->inIdentifier = YES;
        } if(strcmp("meta", name) == 0) {
            NSString *name = nil;
            NSString *content = nil;
            for(int i = 0; atts[i]; i+=2) {
                if(strcmp("name", atts[i]) == 0) {
                    name = [[[NSString alloc] initWithUTF8String:atts[i+1]] autorelease];
                } else if(strcmp("content", atts[i]) == 0) {
                    content = [[[NSString alloc] initWithUTF8String:atts[i+1]] autorelease];
                }
            }
            if(name && content) {
                [context->buildMeta setObject:content forKey:name];
            }
        }
        return;
    }    
    
    if(context->inManifest) {
        if(strcmp("item", name) == 0) {
            NSString *id = nil;
            NSString *href = nil;
            for(int i = 0; atts[i]; i+=2) {
                if(strcmp("id", atts[i]) == 0) {
                    id = [[[NSString alloc] initWithUTF8String:atts[i+1]] autorelease];
                } else if(strcmp("href", atts[i]) == 0) {
                    href = [[[NSString alloc] initWithUTF8String:atts[i+1]] autorelease];
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
                    NSString *idref = [[NSString alloc] initWithUTF8String:atts[i+1]];
                    [context->buildSpine addObject:idref];
                    [idref release];
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
    name = unqualifiedName(name);

    struct contentOpfParsingContext *context = (struct contentOpfParsingContext*)ctx;
    if(context->inMetadata) {
        if(context->inTitle && strcmp("title", name) == 0) {
            context->inTitle = NO;
        } else if(context->inCreator && strcmp("creator", name) == 0) {
            context->inCreator = NO;
        } else if(context->inIdentifier && strcmp("identifier", name) == 0) {
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
    context.buildMeta = [[NSMutableDictionary alloc] init];
    context.buildManifest = [[NSMutableDictionary alloc] init];
    context.buildSpine = [[NSMutableArray alloc] init];
    
    XML_SetStartElementHandler(parser, contentOpfStartElementHandler);
    XML_SetEndElementHandler(parser, contentOpfEndElementHandler);
    XML_SetCharacterDataHandler(parser, contentOpfCharacterDataHandler);
    XML_SetUserData(parser, (void *)&context);    
    XML_Parse(parser, [data bytes], [data length], XML_TRUE);
    XML_ParserFree(parser);
        
    [_meta release];
    _meta = context.buildMeta;
    [_manifest release];
    _manifest = context.buildManifest;
    [_spine release];
    _spine = context.buildSpine;
    
    if(!self->_tocNcxId) {
        // Some ePubs don't seem to specify the toc file as they should.
        // Should probably match based on MIME type rather than extension
        // [no doubt that's wrong sometimes too though...].
        for(NSString *prospectiveTocKey in _manifest.keyEnumerator) {
            if([[[_manifest objectForKey:prospectiveTocKey] pathExtension] caseInsensitiveCompare:@"ncx"] == NSOrderedSame) {
                self->_tocNcxId = [prospectiveTocKey retain];
                break;
            }
        }
    }
    
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
    BOOL inNavLabelText;
    
    NSString *thisLabelText;
    NSString *thisLabelSrc;
    NSUInteger thisLabelPlayOrder;
    
    NSMutableDictionary *buildNavMap;
};

static void tocNcxStartElementHandler(void *ctx, const XML_Char *name, const XML_Char **atts)
{
    name = unqualifiedName(name);
    
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
            } else {
                if(strcmp("text", name) == 0) {
                    context->inNavLabelText = YES;
                }
            }
        }
    }
}

static void tocNcxEndElementHandler(void *ctx, const XML_Char *name)                     
{
    name = unqualifiedName(name);
    
    struct tocNcxParsingContext *context = (struct tocNcxParsingContext *)ctx;
    if(context->inNavMap) { 
        if(context->inNavPoint) {
            if(context->inNavLabelText) {
                if(strcmp("text", name) == 0) {
                    context->inNavLabelText = NO;
                }                
            } else if(context->inNavLabel) {
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
    
    if(context->inNavLabelText) {
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
    NSMutableDictionary *buildNavMap = [[NSMutableDictionary alloc] init];
    if(_anchorPoints && path) {
        NSData *data = [[NSData alloc] initWithContentsOfMappedFile:path];
        XML_Parser parser = XML_ParserCreate("UTF-8");
        
        struct tocNcxParsingContext context = {0};
        context.parser = parser;
        context.buildNavMap = buildNavMap;
        
        XML_SetStartElementHandler(parser, tocNcxStartElementHandler);
        XML_SetEndElementHandler(parser, tocNcxEndElementHandler);
        XML_SetCharacterDataHandler(parser, tocNcxCharacterDataHandler);
        XML_SetUserData(parser, (void *)&context);    
        XML_Parse(parser, [data bytes], [data length], XML_TRUE);
        XML_ParserFree(parser);

        [data release];
        
    }
    
    NSURL *baseUrl = [NSURL fileURLWithPath:path];
    
    NSMutableArray *sectionsBuild = [[NSMutableArray alloc] init];
    if(buildNavMap.count) {
        NSArray *orderedKeys = [[buildNavMap allKeys] sortedArrayUsingSelector:@selector(compare:)];
        for(id key in orderedKeys) {
            THPair *navPoint = [buildNavMap objectForKey:key];
            NSString *name = navPoint.first;
            NSString *src = navPoint.second;

            NSURL *srcUrl = [NSURL URLWithString:src relativeToURL:baseUrl];
            src = [[srcUrl path] stringByReplacingOccurrencesOfString:_path
                                                           withString:@""];
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
                [newSection release];
            }
            [sectionsBuild sortUsingSelector:@selector(compare:)];
        }
    } else {
        EucBookSection *newSection = [[EucBookSection alloc] init];
        [newSection setStartOffset:0];
        [newSection setKind:kBookSectionNondescript];
        [newSection setUuid:[_manifest objectForKey:[_spine objectAtIndex:0]]];
        [newSection setProperty:_title ? _title : NSLocalizedString(@"Start of Book", @"Contents section name for a book with no defined sections or titles")
                         forKey:kBookSectionPropertyTitle];
        [sectionsBuild addObject:newSection];
        [newSection release];            
    }
    
    EucBookSection *lastSection = nil;
    for(EucBookSection *section in sectionsBuild) {
        lastSection.endOffset = section.startOffset;
        [lastSection release];
        lastSection = [section retain];
    }
    lastSection.endOffset = UINT32_MAX;
    [lastSection release];
    
    _sections = sectionsBuild;
    [buildNavMap release];
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
        
        if(!_etextNumber.length|| !_spine.count || !_manifest.count) {
            THWarn(@"Couldn't find toc.ncx location for %@", path);
            [self release];
            return nil;
        } 
        
        NSString *tocPath = nil;
        if(_tocNcxId) {
            NSString *relativeTocPath = [_manifest objectForKey:_tocNcxId];
            if(relativeTocPath) {
                tocPath = [[NSURL URLWithString:[_manifest objectForKey:_tocNcxId] relativeToURL:_contentURL] path];
            }
        }
        [self _parseTocNcx:tocPath];
    
        
        NSString *manifestKey = [_meta objectForKey:@"cover"];
        if(manifestKey) {
            NSString *key = [NSString stringWithFormat:@"gs.ingsmadeoutofotherthin.th.Euclayptus.ePub.%@.manifestOverrides", self.etextNumber];
            self.manifestOverrides = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        }
    }
    return self;
}

- (void)dealloc 
{    
    [_cachedParagraph release];
    [_reader release];
    
    if(_currentPageIndexPointFD) {
        close(_currentPageIndexPointFD);
    }
    
    [_root release];
    [_contentURL release];
    [_tocNcxId release];
    
    [_anchorPoints release];
    
    [_meta release];
    [_spine release];

    [_manifest release];
    [_manifestOverrides release];
    [_manifestUrlsToOverriddenUrls release];
    
    [_sections release];
    [_filteredSections release];

    [super dealloc];
}

- (NSArray *)allUuids
{
    return [_anchorPoints allKeys];
}

- (NSString *)coverPath
{
    NSString *ret = nil;
    
    NSString *manifestKey = [_meta objectForKey:@"cover"];
    if(manifestKey) {
        NSString *documentsRelativeCover = [_manifestOverrides objectForKey:manifestKey];
        if(documentsRelativeCover) {
            NSString *documentsPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByStandardizingPath];
            ret = [documentsPath stringByAppendingPathComponent:documentsRelativeCover];
        } else {
            NSString *relativePath = [_manifest objectForKey:manifestKey];
            if(relativePath) {
                NSURL *fileUrl = [NSURL URLWithString:relativePath relativeToURL:self->_contentURL];
                if([fileUrl isFileURL]) {
                    ret = [fileUrl path];
                }
            }
        }
    }

    return ret;
}

- (void)setCoverPath:(NSString *)coverPath
{
    NSString *manifestKey = [_meta objectForKey:@"cover"];
    if(manifestKey) {
        NSDictionary *manifestOverrides = nil;
        if(coverPath) {
            NSString *documentsPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByStandardizingPath];
            coverPath = [coverPath stringByStandardizingPath];
            NSString *documentsRelativeCoverPath = [coverPath stringByReplacingOccurrencesOfString:documentsPath withString:@""];
            
            manifestOverrides = [NSDictionary dictionaryWithObject:documentsRelativeCoverPath forKey:manifestKey];
        }
        
        NSString *key = [NSString stringWithFormat:@"gs.ingsmadeoutofotherthin.th.Euclayptus.ePub.%@.manifestOverrides", self.etextNumber];
        if(manifestOverrides.count) {
            [[NSUserDefaults standardUserDefaults] setObject:manifestOverrides forKey:key];  
            self.manifestOverrides = manifestOverrides;
        } else {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];  
            self.manifestOverrides = nil;
        }
    }
}

- (void)whitelistSectionsWithUuids:(NSSet *)uuids
{    
    [_filteredSections release];
    _filteredSections = nil;
    
    if(uuids.count) {
        NSMutableArray *filteredSectionsBuild = [NSMutableArray arrayWithCapacity:[self.sections count]];
        for(EucBookSection *section in _sections) {
            if([uuids containsObject:section.uuid] && section.startOffset != section.endOffset ) {
                [filteredSectionsBuild addObject:section];
            }
        }
        _filteredSections = [filteredSectionsBuild retain];
    }
}

- (NSArray *)sections
{
    return _filteredSections ? _filteredSections : _sections;
}

- (NSArray *)bookPageIndexesForFontFamily:(NSString *)fontFamily
{
    NSArray *indexes = [EucFilteredBookPageIndex bookPageIndexesForBook:self forFontFamily:fontFamily];
    if(_filteredSections) {
        NSMutableArray *ranges = [NSMutableArray arrayWithCapacity:_filteredSections.count];
        EucBookSection *lastSection = nil;
        for(EucBookSection *section in _filteredSections) {
            NSRange range;
            range.location = lastSection.endOffset;
            range.length = section.startOffset - range.location;
            if(range.length) {
                [ranges addObject:[NSValue valueWithRange:range]];
            }
            [lastSection release];
            lastSection = [section retain];
        }
        
        for(EucFilteredBookPageIndex *index in indexes) {
            NSRange range;
            range.location = lastSection.endOffset;
            range.length = index.lastOffset + 1 - range.location;
            [index setFilteredByteRanges:[ranges arrayByAddingObject:[NSValue valueWithRange:range]]];
        }
        
        [lastSection release];
    }
    return indexes;
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
    return [files autorelease];
}

- (id<EucBookReader>)reader
{
    if(!_reader) {
        _reader = [[EucEPubBookReader alloc] initWithBook:self];
    }
    return _reader;
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

- (void)setCurrentPageIndexPointForUuid:(NSString *)uuid
{
    EucBookPageIndexPoint *indexPoint = [[EucBookPageIndexPoint alloc] init];
    indexPoint.startOfParagraphByteOffset = [self byteOffsetForUuid:uuid];
    self.currentPageIndexPoint = indexPoint;
    [indexPoint release];
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
    for(EucBookSection *section in self.sections) {
        if([section.uuid isEqualToString:uuid]) {
            return section;
        }
    }    
    return nil;    
}

- (BOOL)hasByteOffsetForUuid:(NSString *)uuid
{
    return [_anchorPoints objectForKey:uuid] != nil;    
}

- (NSUInteger)byteOffsetForUuid:(NSString *)uuid
{
    return [[_anchorPoints objectForKey:uuid] unsignedIntegerValue];    
}

- (EucBookSection *)topLevelSectionForByteOffset:(NSUInteger)byteOffset
{
    EucBookSection *section = [self.sections objectAtIndex:0];
    for(EucBookSection *potentialSection in self.sections) {
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
    for(EucBookSection *section in [self.sections reverseObjectEnumerator]) {
        if(section.startOffset < byteOffset) {
            return section;
        }
    }
    return nil;
}

- (EucBookSection *)nextTopLevelSectionForByteOffset:(NSUInteger)byteOffset
{
    for(EucBookSection *section in self.sections) {
        if(section.startOffset > byteOffset) {
            return section;
        }
    }
    return nil;
}

- (void)setManifestOverrides:(NSDictionary *)manifestOverrides 
{
    if(_manifestOverrides != manifestOverrides) {
        [_manifestOverrides release];
        [_manifestUrlsToOverriddenUrls release];
        
        if(manifestOverrides.count) {
            _manifestOverrides = [manifestOverrides retain];

            NSString *documentsPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByStandardizingPath];
            NSURL *documentsURL = [NSURL fileURLWithPath:documentsPath isDirectory:YES];
            
            NSMutableDictionary *manifestUrlsToOverriddenUrls = [NSMutableDictionary dictionary];
            for(NSString *key in [manifestOverrides keyEnumerator]) {
                NSString *manifestPath = [_manifest objectForKey:key];
                NSString *overriddenPath = [manifestOverrides objectForKey:key];
                if(manifestPath && overriddenPath) {
                    NSURL *manifestUrl = [[NSURL URLWithString:manifestPath relativeToURL:_contentURL] absoluteURL];
                    NSURL *overriddenUrl = [[NSURL URLWithString:overriddenPath relativeToURL:documentsURL] absoluteURL];
                    if(manifestUrl && overriddenUrl) {
                        [manifestUrlsToOverriddenUrls setObject:overriddenUrl forKey:manifestUrl];
                    }
                }
            }
            _manifestUrlsToOverriddenUrls = [manifestUrlsToOverriddenUrls retain];
        } else {
            _manifestOverrides = nil;
            _manifestUrlsToOverriddenUrls = nil;
        }
    }
}

- (NSData *)dataForFileAtURL:(NSURL *)url;
{
    NSData *ret = nil;
    url = [url absoluteURL];
    NSURL *overridden = [_manifestUrlsToOverriddenUrls objectForKey:url];
    if(overridden) {
        ret = [NSData dataWithContentsOfMappedFile:[overridden path]];
    }
    if(!ret) {
        ret = [NSData dataWithContentsOfMappedFile:[url path]];
    }
    return ret;
}

- (NSArray *)paragraphWordsForParagraphWithId:(uint32_t)paragraphId
{
    if(_cachedParagraph && [_cachedParagraph byteOffset] == paragraphId) {
        return [_cachedParagraph words];
    }
    id<EucBookReader> reader = self.reader;
    id<EucBookParagraph> paragraph = [reader paragraphAtOffset:paragraphId maxOffset:-1];
    
    if(_cachedParagraph != paragraph) {
        [_cachedParagraph release];
        _cachedParagraph = [paragraph retain];  
    }
    
    return paragraph.words;
}

- (uint32_t)paragraphIdForParagraphAfterParagraphWithId:(uint32_t)paragraphId
{
    if(_cachedParagraph && [_cachedParagraph byteOffset] == paragraphId) {
        return [_cachedParagraph nextParagraphByteOffset];
    }    
    id<EucBookReader> reader = self.reader;
    id<EucBookParagraph> paragraph = [reader paragraphAtOffset:paragraphId maxOffset:-1];
    
    if(_cachedParagraph != paragraph) {
        [_cachedParagraph release];
        _cachedParagraph = [paragraph retain];  
    }
    
    return paragraph.nextParagraphByteOffset;
}

- (void)getCurrentParagraphId:(uint32_t *)id wordOffset:(uint32_t *)offset
{
    EucBookPageIndexPoint *currentPageIndexPoint = self.currentPageIndexPoint;
    if(id) {
        *id = currentPageIndexPoint.startOfParagraphByteOffset;
    }
    if(offset) {
        *offset = currentPageIndexPoint.startOfPageParagraphWordOffset;
    }
}

@end
