//
//  EucBUpeBook.m
//  libEucalyptus
//
//  Created by James Montgomerie on 12/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//


#import "THLog.h"
#import "EucBUpeBook.h"
#import "EucBookPageIndex.h"
#import "EucFilteredBookPageIndex.h"
#import "EucBookPageIndexPoint.h"
#import "EucBookReader.h"
#import "EucBookParagraph.h"
#import "EucBookSection.h"
#import "THPair.h"
#import "THRegex.h"
#import "THNSURLAdditions.h"
#import "expat.h"

#import "EucCSSXMLTree.h"
#import "EucCSSIntermediateDocument.h"
#import "EucCSSLayouter.h"

#import <fcntl.h>
#import <sys/stat.h>
#import <sys/mman.h>

@interface EucBUpeBook ()
@property (nonatomic, retain) NSDictionary *manifestOverrides;
@end

@implementation EucBUpeBook

@synthesize navPoints = _navPoints;
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
    
    if(strcmp("rootfile", name) == 0) {
        for(int i = 0; atts[i]; i+=2) {
            if(strcmp("full-path", atts[i]) == 0) {
                *((NSString **)ctx) = [NSString stringWithUTF8String:atts[i+1]];
            }
        }
    }
}    

- (NSURL *)_rootfileFromContainerXml:(NSURL *)url
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *rootfileFullPath = nil;
    NSURL *ret = nil;
    
    NSData *data = [self dataForURL:url];
    if(data) {
        XML_Parser parser = XML_ParserCreate("UTF-8");
        XML_SetStartElementHandler(parser, containerXMLParsingStartElementHandler);
        XML_SetUserData(parser, (void *)&rootfileFullPath);    
        XML_Parse(parser, [data bytes], [data length], XML_TRUE);
        XML_ParserFree(parser);
        
        if(rootfileFullPath) {
            ret =  [[NSURL alloc] initWithString:rootfileFullPath relativeToURL:_root];
        }
    }
    
    [pool drain];
    
    return [ret autorelease];
}

#pragma mark -
#pragma mark content.opf parsing

struct contentOpfParsingContext
{
    XML_Parser parser;
    
    NSURL *url;
    
    EucBUpeBook *self;
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
                    NSString *relativeHref = [NSString stringWithUTF8String:atts[i+1]];
                    NSURL *hrefUrl = [NSURL URLWithString:relativeHref relativeToURL:context->url];
                    href = [hrefUrl pathRelativeTo:context->self->_root];
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

- (BOOL)_parseContentOpf:(NSURL *)url
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    BOOL ret = NO;
    NSData *data = [self dataForURL:url];
    if(data) {
        XML_Parser parser = XML_ParserCreate("UTF-8");
        
        struct contentOpfParsingContext context = {0};
        context.url = url;
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
        
        ret = YES;
    }
    
    [pool drain];
 
    return ret;
}

#pragma mark -
#pragma mark toc.ncx parsing

struct tocNcxParsingContext
{
    XML_Parser parser;
    EucBUpeBook *self;
    
    NSURL *url;
    
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
                    [context->buildNavMap setObject:[THPair pairWithFirst:context->thisLabelText 
                                                                   second:[[NSURL URLWithString:context->thisLabelSrc 
                                                                                 relativeToURL:context->url] pathRelativeTo:context->self->_root]]
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


- (void)_parseTocNcx:(NSURL *)url
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSMutableDictionary *buildNavMap = [[NSMutableDictionary alloc] init];
    if(url) {
        NSData *data = [self dataForURL:url];
        if(data) {
            XML_Parser parser = XML_ParserCreate("UTF-8");
            
            struct tocNcxParsingContext context = {0};
            context.parser = parser;
            context.url = url;
            context.self = self;
            context.buildNavMap = buildNavMap;
            
            XML_SetStartElementHandler(parser, tocNcxStartElementHandler);
            XML_SetEndElementHandler(parser, tocNcxEndElementHandler);
            XML_SetCharacterDataHandler(parser, tocNcxCharacterDataHandler);
            XML_SetUserData(parser, (void *)&context);    
            XML_Parse(parser, [data bytes], [data length], XML_TRUE);
            XML_ParserFree(parser);
        }   
    }
    
    NSMutableArray *navPointsBuild = [[NSMutableArray alloc] init];
    if(buildNavMap.count) {
        NSArray *orderedKeys = [[buildNavMap allKeys] sortedArrayUsingSelector:@selector(compare:)];
        for(id key in orderedKeys) {
            [navPointsBuild addObject:[buildNavMap objectForKey:key]];
        }
    } else {
        [navPointsBuild addPairWithFirst:NSLocalizedString(@"Start of Book", @"Contents section name for a book with no defined sections or titles")
                                  second:[_manifest objectForKey:[_spine objectAtIndex:0]]];
    }
    _navPoints = navPointsBuild;
    
    [buildNavMap release];
    
    [pool drain];
}

#pragma mark -

- (id)initWithPath:(NSString *)path
{
    if((self = [super init])) {
        self.path = path;
        _root = [[NSURL fileURLWithPath:path isDirectory:YES] retain];
                
        NSURL *contentUrl = [self _rootfileFromContainerXml:[NSURL URLWithString:@"META-INF/container.xml" relativeToURL:_root]];
                
        if(contentUrl && [self _parseContentOpf:contentUrl]) {
            if(!_etextNumber.length|| !_spine.count || !_manifest.count) {
                THWarn(@"Malformed ePub (no ID, no spine, or no manifest) at %@", path);
                [self release];
                return nil;
            } 
            
            // TOC url is allowed to be nil.
            NSString *tocPath = [_manifest objectForKey:_tocNcxId];\
            NSURL *tocUrl = nil;
            if(tocPath) {
                tocUrl = [NSURL URLWithString:tocPath relativeToURL:_root];
            }
            [self _parseTocNcx:tocUrl];
            
            NSString *manifestKey = [_meta objectForKey:@"cover"];
            if(manifestKey) {
                NSString *key = [NSString stringWithFormat:@"gs.ingsmadeoutofotherthin.th.Euclayptus.bUpe.%@.manifestOverrides", self.etextNumber];
                self.manifestOverrides = [[NSUserDefaults standardUserDefaults] objectForKey:key];
            }
        } else {
            THWarn(@"Couldn't find content for ePub at %@", path);
            [self release];
            return nil;            
        }
    }
    return self;
}

- (void)dealloc 
{        
    if(_currentPageIndexPointFD) {
        close(_currentPageIndexPointFD);
    }
    
    [_root release];
    [_tocNcxId release];
    
    [_navPoints release];
    
    [_meta release];
    [_spine release];
    
    [_manifest release];
    [_manifestOverrides release];
    [_manifestUrlsToOverriddenUrls release];
    
    [super dealloc];
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
            ret = [[_manifest objectForKey:manifestKey] path];
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
    /*[_filteredSections release];
    _filteredSections = nil;
    
    if(uuids.count) {
        NSMutableArray *filteredSectionsBuild = [NSMutableArray arrayWithCapacity:[self.sections count]];
        for(EucBookSection *section in _sections) {
            if([uuids containsObject:section.uuid] && section.startOffset != section.endOffset ) {
                [filteredSectionsBuild addObject:section];
            }
        }
        _filteredSections = [filteredSectionsBuild retain];
    }*/
}

- (NSArray *)bookPageIndexes
{
    NSArray *indexes = [EucFilteredBookPageIndex bookPageIndexesForBook:self];
    /*if(_filteredSections) {
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
    }*/
    return indexes;
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

- (void)setCurrentPageIndexPointForId:(NSString *)anchor
{
    self.currentPageIndexPoint = [self indexPointForId:anchor];
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
    return NSClassFromString(@"EucBUpePageLayoutController");
}

- (EucBookPageIndexPoint *)indexPointForId:(NSString *)identifier
{
    EucBookPageIndexPoint *indexPoint = [[EucBookPageIndexPoint alloc] init];
    
    NSString *file = nil;
    NSString *fragment = nil;
    
    THRegex *fragmentFinder = [THRegex regexWithPOSIXRegex:@"^(.*)#(.*)$"];
    if([fragmentFinder matchString:identifier]) {
        file = [fragmentFinder match:1];
        fragment = [fragmentFinder match:2];
    } else {
        file = identifier;
    }
    
    for(NSString *identifier in [_manifest keyEnumerator]) {
        NSString *path = [_manifest objectForKey:identifier];
        if([path isEqualToString:file] && [_spine containsObject:identifier]) {
            NSURL *url = [NSURL URLWithString:path relativeToURL:_root];
            EucCSSIntermediateDocument *document = [self intermediateDocumentForURL:url];
            EucCSSIntermediateDocumentNode *node = fragment ? [document nodeForKey:[document nodeKeyForId:fragment]] : document.rootNode;
            if(!node) {
                node = document.rootNode;
            }
            
            // The point is dependent on the layout algorithm.
            // (It depends on how the text is split into runs).
            EucCSSLayouter *layouter = [[EucCSSLayouter alloc] init];
            layouter.document = document;
            EucCSSLayoutPoint layoutPoint = [layouter layoutPointForNode:node];
            [layouter release];
            
            indexPoint.source = [_spine indexOfObject:identifier];
            indexPoint.block = layoutPoint.nodeKey;
            indexPoint.word = layoutPoint.word;
            indexPoint.element = layoutPoint.element;
        }
    }
    
    return [indexPoint autorelease];
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
                    NSURL *manifestUrl = [[NSURL URLWithString:manifestPath relativeToURL:_root] absoluteURL];
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


- (NSData *)dataForURL:(NSURL *)url
{
    NSData *ret = nil;
    url = [url absoluteURL];
    NSURL *overridden = [_manifestUrlsToOverriddenUrls objectForKey:url];
    if(overridden) {
        ret = [[NSData alloc] initWithContentsOfMappedFile:[overridden path]];
    }
    if(!ret) {
        ret = [[NSData alloc] initWithContentsOfMappedFile:[url path]];
    }
    return [ret autorelease];
}

- (id<EucCSSDocumentTree>)documentTreeForURL:(NSURL *)url
{
    NSData *data = [self dataForURL:url];
    if(data) {
        return  [[[EucCSSXMLTree alloc] initWithData:data] autorelease];
    }
    return nil;
}

- (EucCSSIntermediateDocument *)intermediateDocumentForURL:(NSURL *)url
{
    EucCSSIntermediateDocument *document = [_documentCache objectForKey:url];
    if(!document) {
        EucCSSXMLTree *documentTree = [self documentTreeForURL:url];
        if(documentTree) {
            document = [[EucCSSIntermediateDocument alloc] initWithDocumentTree:documentTree
                                                                         forURL:url
                                                                     dataSource:self
                                                                    baseCSSPath:[[NSBundle mainBundle] pathForResource:@"EPubDefault" ofType:@"css"]];            
            if(!_documentCache) {
                _documentCache = [[NSMutableDictionary alloc] init];
            }
            [_documentCache setObject:document forKey:url];
            
            [document release];
        }
    }
    return document;
}

- (EucCSSIntermediateDocument *)intermediateDocumentForIndexPoint:(EucBookPageIndexPoint *)point
{
    NSUInteger spineIndex = point.source;
    if(spineIndex < _spine.count) {
        NSString *spineId = [_spine objectAtIndex:point.source];
        NSString *manifestPath = [_manifest objectForKey:spineId];
        if(manifestPath) {
            NSURL *url = [NSURL URLWithString:manifestPath relativeToURL:_root];
            if(url) {
                return [self intermediateDocumentForURL:url];
            }
        }
    }
    return nil;
}

@end