//
//  EucBUpeBook.m
//  libEucalyptus
//
//  Created by James Montgomerie on 12/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//#import "EucCSSLayouter.h"



#import "THLog.h"
#import "EucBUpeBook.h"
#import "EucBookNavPoint.h"
#import "EucBookIndex.h"
#import "EucBookPageIndex.h"
#import "EucFilteredBookPageIndex.h"
#import "EucBookPageIndexPoint.h"
#import "THPair.h"
#import "THRegex.h"
#import "THNSURLAdditions.h"

#import "EucConfiguration.h"
#import "EucCSSLayoutRunExtractor.h"
#import "EucCSSXMLTree.h"
#import "EucCSSXHTMLTreeNode.h"
#import "EucCSSIntermediateDocument.h"
#import "EucCSSIntermediateDocumentNode.h"

#import "expat.h"

#import <fcntl.h>
#import <unistd.h>
#import <sys/stat.h>
#import <sys/mman.h>

#define kMaxCachedDocuments 3

@interface TocNcxParsingContextNavPointInfo : NSObject {
    NSString *_text;
    NSString *_src;
    NSUInteger _playOrder;
    
    BOOL _inNavLabel;
    BOOL _inNavLabelText;
}

@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) NSString *src;
@property (nonatomic, assign) NSUInteger playOrder;
@property (nonatomic, assign) BOOL inNavLabel;
@property (nonatomic, assign) BOOL inNavLabelText;

@end

@implementation TocNcxParsingContextNavPointInfo

@synthesize text = _text;
@synthesize src = _src;
@synthesize playOrder = _playOrder;
@synthesize inNavLabel = _inNavLabel;
@synthesize inNavLabelText = _inNavLabelText;

- (void)dealloc
{
    [_text release];
    [_src release];
    [super dealloc];
}

@end

@interface EucBUpeBook ()
@property (nonatomic, retain) NSDictionary *manifestOverrides;

- (EucCSSIntermediateDocument *)_intermediateDocumentForURL:(NSURL *)url;
- (void)_restorePersistedCachableDataIfPossible;

@end

@implementation EucBUpeBook

@synthesize navPoints = _navPoints;
@synthesize manifestOverrides = _manifestOverrides;
@synthesize persistsPositionAutomatically = _persistsPositionAutomatically;
@synthesize idToIndexPoint = _idToIndexPoint;

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
    BOOL inGuide;
    
    BOOL inManifest;
    NSMutableDictionary *buildMeta;
    NSMutableDictionary *buildManifest;
    NSMutableArray *buildSpine;
    
    NSString *guideCoverItemHref;
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
    
    if(context->inGuide) {
        // The only thing we use the guide for is detecting the covrer page.
        // TOC is provided by the ncx file.
        if(strcmp("reference", name) == 0) {
            const XML_Char *type = NULL;
            const XML_Char *href = NULL;
            for(int i = 0; atts[i]; i+=2) {
                if(strcmp("type", atts[i]) == 0) {
                    type = atts[i+1];
                } else if(strcmp("href", atts[i]) == 0) {
                    href = atts[i+1];
                } 
            }
            if(type && href) {
                if(strcmp("cover", type) == 0) {
                    context->guideCoverItemHref = [NSString stringWithUTF8String:href];
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
    } else if(strcmp("guide", name) == 0) {
        context->inGuide = YES;
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
    } else if(context->inGuide) {
        if(strcmp("guide", name) == 0) {
            context->inGuide = NO;
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
        
        if(context->inTitle) {
            if(!context->self.title) {
                context->self.title = string;
            } else {
                context->self.title = [context->self.title stringByAppendingString:string];
            }
        } else if(context->inCreator) {
            if(!context->self.author) {
                context->self.author  = string;
            } else {
                context->self.author = [context->self.author stringByAppendingString:string];
            }            
        } else if(context->inIdentifier) {
            if(!context->self.etextNumber) {
                context->self.etextNumber  = string;
            } else {
                context->self.etextNumber = [context->self.etextNumber stringByAppendingString:string];
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
        
        [_guideCoverItemURL release];
        _guideCoverItemURL = nil;
        NSString *guideCoverHref = context.guideCoverItemHref; 
        if(guideCoverHref) {
            // Google Books have malformed guides that have href
            // corresponding to  manifest IDs rather than relative URLs, so 
            // we attempt to see if that's the case here and fix them up.

            // First, look in the maniest to see if a file exists at the 
            // specified href, as the spec requires.
            NSURL *hrefUrl = [NSURL URLWithString:guideCoverHref relativeToURL:url];
            NSString *relativeGuideCoverItemHref = [hrefUrl pathRelativeTo:_root];
            BOOL coverItemHrefExistsInManifest = NO;
            for(NSString *manifestEntry in _manifest) {
                if([manifestEntry isEqual:relativeGuideCoverItemHref]) {
                    coverItemHrefExistsInManifest = YES;
                }
            }
            if(!coverItemHrefExistsInManifest) {
                // If there's no file at the specified href, see if the 
                // href instead refers to a valid manifest ID.
                NSString *alternativePath = [_manifest objectForKey:guideCoverHref];
                if(alternativePath) {
                    hrefUrl = [NSURL URLWithString:alternativePath relativeToURL:_root];
                } else {
                    // We'll leave things as they are - there's the posibility
                    // that this is a valid filename that's not in the manifest
                    // (although the spec doesn't allow this either).
                }
            }
            
            _guideCoverItemURL = [[hrefUrl absoluteURL] retain];
        }
        
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
    
    NSString *thisLabelText;
    NSString *thisLabelSrc;
    NSUInteger thisLabelPlayOrder;
    
    NSMutableArray *navPointStack;
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
        if(strcmp("navPoint", name) == 0) {
            TocNcxParsingContextNavPointInfo *navPointInfo = [[TocNcxParsingContextNavPointInfo alloc] init];
            [context->navPointStack addObject:navPointInfo];
            [navPointInfo release];
            for(int i = 0; atts[i]; i+=2) {
                if(strcmp("playOrder", atts[i]) == 0) {
                    navPointInfo.playOrder = atoi(atts[i+1]);
                }
            }
        } else if(context->navPointStack.count) {
            TocNcxParsingContextNavPointInfo *navPointInfo = [context->navPointStack lastObject];
            if(!navPointInfo.inNavLabel) {
                if(strcmp("navLabel", name) == 0) {
                    navPointInfo.inNavLabel = YES;
                } else if(strcmp("content", name) == 0) {
                    for(int i = 0; atts[i]; i+=2) {
                        if(strcmp("src", atts[i]) == 0) {
                            TocNcxParsingContextNavPointInfo *navPointInfo = [context->navPointStack lastObject];
                            navPointInfo.src = [NSString stringWithUTF8String:atts[i+1]];
                        }
                    }            
                }
            } else {
                if(strcmp("text", name) == 0) {
                    navPointInfo.inNavLabelText = YES;
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
        if(context->navPointStack.count) {
            TocNcxParsingContextNavPointInfo *navPointInfo = [context->navPointStack lastObject];
            if(navPointInfo.inNavLabelText) {
                if(strcmp("text", name) == 0) {
                    navPointInfo.inNavLabelText = NO;
                }                
            } else if(navPointInfo.inNavLabel) {
                if(strcmp("navLabel", name) == 0) {
                    navPointInfo.inNavLabel = NO;
                }
            } else if(strcmp("navPoint", name) == 0) {
                TocNcxParsingContextNavPointInfo *navPointInfo = [context->navPointStack lastObject];

                NSString *src = navPointInfo.src;
                if(src) {
                    NSString *text = navPointInfo.text;
                    if(text) {
                        NSString *uuid = [[NSURL URLWithString:src relativeToURL:context->url] absoluteString];
                        [context->buildNavMap setObject:[EucBookNavPoint navPointWithText:text uuid:uuid level:(context->navPointStack).count - 1]
                                                 forKey:[NSNumber numberWithUnsignedInteger:navPointInfo.playOrder]];
                    }
                }
                
                [context->navPointStack removeLastObject];
            }
        } else if(strcmp("navMap", name) == 0) {
            context->inNavMap = NO;
        } 
    }
}

static void tocNcxCharacterDataHandler(void *ctx, const XML_Char *chars, int len) 
{
    struct tocNcxParsingContext *context = (struct tocNcxParsingContext *)ctx;
    if(context->navPointStack.count) {
        TocNcxParsingContextNavPointInfo *navPointInfo = [context->navPointStack lastObject];
        if(navPointInfo.inNavLabelText) {
            NSString *text = [[NSString alloc] initWithBytes:chars length:len encoding:NSUTF8StringEncoding];

            NSString *oldText = navPointInfo.text;
            if(oldText && text.length) {
                navPointInfo.text = [oldText stringByAppendingString:text];
            } else {
                navPointInfo.text = text;
            }
            
            [text release];
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
            context.navPointStack = [[NSMutableArray alloc] init];
            context.buildNavMap = buildNavMap;
            
            XML_SetStartElementHandler(parser, tocNcxStartElementHandler);
            XML_SetEndElementHandler(parser, tocNcxEndElementHandler);
            XML_SetCharacterDataHandler(parser, tocNcxCharacterDataHandler);
            XML_SetUserData(parser, (void *)&context);    
            XML_Parse(parser, [data bytes], [data length], XML_TRUE);
            XML_ParserFree(parser);
            
            [context.navPointStack release];
        }   
    }
    
    NSMutableArray *navPointsBuild = [[NSMutableArray alloc] init];
    if(buildNavMap.count) {
        NSArray *orderedKeys = [[buildNavMap allKeys] sortedArrayUsingSelector:@selector(compare:)];
        for(id key in orderedKeys) {
            [navPointsBuild addObject:[buildNavMap objectForKey:key]];
        }
    } else {
        [navPointsBuild addObject:[EucBookNavPoint navPointWithText:NSLocalizedString(@"Start of Book", @"Contents section name for a book with no defined sections or titles")
                                                               uuid:[[NSURL URLWithString:[_manifest objectForKey:[_spine objectAtIndex:0]] relativeToURL:_root] absoluteString]
                                                              level:0]];
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
            NSString *tocPath = [_manifest objectForKey:_tocNcxId];
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
    [_currentPageIndexPoint release];
    if(_currentPageIndexPointFD) {
        close(_currentPageIndexPointFD);
    }
    
    _documentCache.evictsOnMemoryWarnings = NO;
    [_documentCache release];
    
    [_root release];
    [_tocNcxId release];
    
    [_navPoints release];
    
    [_meta release];
    [_spine release];
    
    [_guideCoverItemURL release];
    [_manifest release];
    [_manifestOverrides release];
    [_manifestUrlsToOverriddenUrls release];
    [_coverPath release];
	[_idToIndexPoint release];

    free(_indexSourceScaleFactors);
    
    [super dealloc];
}

- (BOOL)documentTreeIsHTML:(id<EucCSSDocumentTree>)documentTree
{
    return YES;
}

- (NSArray *)baseCSSPathsForDocumentTree:(id<EucCSSDocumentTree>)documentTree
{
    return [NSArray arrayWithObject:[[NSBundle mainBundle] pathForResource:@"EPubDefault" ofType:@"css"]];
}

- (NSArray *)userCSSPathsForDocumentTree:(id<EucCSSDocumentTree>)documentTree
{
    return [NSArray arrayWithObject:[[NSBundle mainBundle] pathForResource:@"EPubOverrides" ofType:@"css"]];
}

- (NSString *)coverPath
{
    NSString *ret = nil;
    
    NSString *manifestKey = [_meta objectForKey:@"cover"];
    if(!manifestKey) {
        manifestKey = @"cover-image"; // Should be specified, but sometimes it's not in real life...
    }
    if(manifestKey) {
        NSString *documentsRelativeCover = [_manifestOverrides objectForKey:manifestKey];
        if(documentsRelativeCover) {
            NSString *documentsPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByStandardizingPath];
            ret = [documentsPath stringByAppendingPathComponent:documentsRelativeCover];
        } else {
            NSString *relativePath = [_manifest objectForKey:manifestKey];
            if(relativePath) {
                ret = [[NSURL URLWithString:relativePath relativeToURL:_root] path];
            }
        }
    } 
    if(!ret) {
        ret = _coverPath;
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
    if(_coverPath != coverPath) {
        [_coverPath release];
        _coverPath = [coverPath retain];
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

- (EucBookIndex *)bookIndex
{
    EucBookIndex *index = [EucBookIndex bookIndexForBook:self];
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
    return index;
}

- (EucBookPageIndexPoint *)currentPageIndexPoint
{
    if(_persistsPositionAutomatically) {
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
                    off_t size = lseek(_currentPageIndexPointFD, 0, SEEK_END);
                    if(size == 0) {
                        EucBookPageIndexPoint *cover = [[EucBookPageIndexPoint alloc] init];
                        [self setCurrentPageIndexPoint:cover];
                        return [cover autorelease]; 
                    } else {
                        lseek(_currentPageIndexPointFD, 0, SEEK_SET);
                    }
                } else {
                    _currentPageIndexPointFD = 0;
                    THWarn(@"Could not open file at %@, error %d", path, errno);
                }
            }
        }
        
        return [EucBookPageIndexPoint bookPageIndexPointFromOpenFD:_currentPageIndexPointFD];
    } else {
        if(!_currentPageIndexPoint) {
            _currentPageIndexPoint = [[EucBookPageIndexPoint alloc] init];
        }
        return _currentPageIndexPoint;
    }
}

- (void)setCurrentPageIndexPoint:(EucBookPageIndexPoint *)currentPage
{
    if(_persistsPositionAutomatically) {
        if(!_currentPageIndexPointFD) {
            [self currentPageIndexPoint]; // Will create a file if necessary.
        }
        lseek(_currentPageIndexPointFD, SEEK_SET, 0); 
        [currentPage writeToOpenFD:_currentPageIndexPointFD];
    } else {
        if(currentPage != _currentPageIndexPoint) {
            [_currentPageIndexPoint release];
            _currentPageIndexPoint = [currentPage retain];
        }
    }
}

- (Class)pageLayoutControllerClass
{
    return NSClassFromString(@"EucBUpePageLayoutController");
}

- (NSDictionary *)buildIdToIndexPoint
{
    NSMutableDictionary *buildIdToIndexPoint = [[NSMutableDictionary alloc] init];
    EucBookPageIndexPoint *sourceIndexPoint = [[EucBookPageIndexPoint alloc] init];
    uint32_t source = 0;
    
    NSUInteger fontSizes[30] = {0};
    
    for(;;) {
        NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init]; 
        EucCSSIntermediateDocument *document = [self intermediateDocumentForIndexPoint:sourceIndexPoint];
        if(!document) {
            [innerPool drain];
            break;
        }
        
        NSURL *documentUrl = document.url;
        EucBookPageIndexPoint *thisIndexPoint = [sourceIndexPoint copy];
        [buildIdToIndexPoint setObject:thisIndexPoint forKey:[documentUrl absoluteString]];
        [thisIndexPoint release];
                
        NSDictionary *localIdsToNodes = document.idToNodeKey;
        if(localIdsToNodes) {
            EucCSSLayoutRunExtractor *extractor = [[EucCSSLayoutRunExtractor alloc] initWithDocument:document];            
            NSString *documentUrlString = [documentUrl absoluteString];
            for(NSString *localId in [localIdsToNodes keyEnumerator]) {
                NSAutoreleasePool *innerInnerPool = [[NSAutoreleasePool alloc] init]; 
                
                EucCSSIntermediateDocumentNode *node = [document nodeForKey:[document nodeKeyForId:localId]];
                EucCSSLayoutPoint layoutPoint = [extractor layoutPointForNode:node];                   
                EucBookPageIndexPoint *indexPoint = [[EucBookPageIndexPoint alloc] init];
                indexPoint.source = source;
                indexPoint.block = layoutPoint.nodeKey;
                indexPoint.word = layoutPoint.word;
                indexPoint.element = layoutPoint.element;
                
                NSString *globalURLString = [documentUrlString stringByAppendingFormat:@"#%@", localId];
                NSURL *globalUrl = [NSURL URLWithString:globalURLString];
                if(globalUrl) {
                    globalURLString = [globalUrl absoluteString];
                }
                [buildIdToIndexPoint setObject:indexPoint forKey:globalURLString];
                
                [indexPoint release];
                
                [innerInnerPool drain];
            }
            [extractor release];
        }
        
        // Bit messy to do this here.  Basically, we're trying to find the 
        // median text size, so that we can scale it to Eucalyptus' default
        // text size for books that the publisher has crazily chosen a tiny
        // or huge text size by default.  It's efficient to do it here when 
        // we have the documents open anyway, and we can persist it alongside
        // the _idToIndexPoint map in -persistCachableData.
        EucCSSIntermediateDocumentNode *node = document.rootNode;
        while((node = node.nextDisplayable)) {
            if(node.isTextNode) {
                off_t pointSize = roundf([node textPointSizeWithScaleFactor:1.0f]);
                ++fontSizes[MIN(pointSize, 29)];
            }
        }
                
        sourceIndexPoint.source = ++source;
        
        [innerPool drain];
    }
        
    [sourceIndexPoint release];
    
    NSUInteger bestTotalNodeCount = 0;
    NSUInteger bestTotalNodeIndex = NSUIntegerMax;
    for(NSUInteger i = 0; i < 30; ++i) {
        if(fontSizes[i] > bestTotalNodeCount) {
            bestTotalNodeCount = fontSizes[i];
            bestTotalNodeIndex = i;
        }
    }
    
    _normalisingScaleFactor = [[EucConfiguration objectForKey:EucConfigurationDefaultFontSizeKey] floatValue] / (CGFloat)bestTotalNodeIndex;
    
    return [buildIdToIndexPoint autorelease];
}

- (NSDictionary *)idToIndexPoint
{
    if(!_idToIndexPoint) {
        _idToIndexPoint = [[self buildIdToIndexPoint] retain];
    }
    return _idToIndexPoint;
}

- (EucBookPageIndexPoint *)indexPointForId:(NSString *)identifier
{
    return [self.idToIndexPoint objectForKey:identifier];
}

- (CGFloat)normalisingScaleFactor
{
    [self idToIndexPoint]; // Ensure calculated
    return _normalisingScaleFactor != 0.0f ? _normalisingScaleFactor : 1.0f;
}

- (float *)indexSourceScaleFactors
{
    if(!_indexSourceScaleFactors) {
        NSMutableArray *sizes = [NSMutableArray array];
        NSUInteger total = 0;
        
        EucBookPageIndexPoint *point = [[EucBookPageIndexPoint alloc] init];
        NSUInteger i = 0;
        BOOL existed;
        do {
            existed = NO;
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            point.source = i;
            
            NSURL *documentURL = [self documentURLForIndexPoint:point];
            if(documentURL) {
                NSData *data = [self dataForURL:documentURL];
                if(data) {
                    NSUInteger length = data.length;
                    total += length;
                    [sizes addObject:[NSNumber numberWithInteger:length]];
                    existed = YES;
                }
            }
            
            ++i;
            
            [pool drain];
        } while(existed);
    
        [point release];
        
        i = 0;
        float *scaleFactors = malloc(sizes.count * sizeof(float));
        for(NSNumber *size in sizes) {
            scaleFactors[i] = size.floatValue / (float)total;
            ++i;
        }
    
        _indexSourceScaleFactors = scaleFactors;
    }
    
    return _indexSourceScaleFactors;
}

- (float)estimatedPercentageForIndexPoint:(EucBookPageIndexPoint *)point
{
    float ret = 0;
    
    float *scaleFactors = self.indexSourceScaleFactors;
    uint32_t source = point.source;
    for(uint32_t i = 0; i < source; ++i) {
        ret += 100.0f * scaleFactors[i];
    }

    if(point.block) {
        ret += ([[self intermediateDocumentForIndexPoint:point] estimatedPercentageForNodeWithKey:point.block] * scaleFactors[source]);
    }

    return ret;
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
        return [[[EucCSSXMLTree alloc] initWithData:data xmlTreeNodeClass:[EucCSSXHTMLTreeNode class]] autorelease];
    }
    return nil;
}

- (NSURL *)documentURLForIndexPoint:(EucBookPageIndexPoint *)point
{
    NSUInteger spineIndex = point.source;
    if(spineIndex < _spine.count) {
        NSString *spineId = [_spine objectAtIndex:point.source];
        NSString *manifestPath = [_manifest objectForKey:spineId];
        if(manifestPath) {
            return [[NSURL URLWithString:manifestPath relativeToURL:_root] absoluteURL];
        }
    }
    return nil;
}

- (EucCSSIntermediateDocument *)_intermediateDocumentForURL:(NSURL *)url
{
    if(!_documentCache) {
        _documentCache = [[THCache alloc] init];
        _documentCache.generationLifetime = kMaxCachedDocuments;
        _documentCache.evictsOnMemoryWarnings = YES;
    }
    EucCSSIntermediateDocument *document = [_documentCache objectForKey:url];
    if(!document) {
        id<EucCSSDocumentTree> documentTree = [self documentTreeForURL:url];
        if(documentTree) {
            document = [[EucCSSIntermediateDocument alloc] initWithDocumentTree:documentTree
                                                                         forURL:url
                                                                     dataSource:self
                                                                   baseCSSPaths:[self baseCSSPathsForDocumentTree:documentTree]
                                                                   userCSSPaths:[self userCSSPathsForDocumentTree:documentTree]
                                                                         isHTML:[self documentTreeIsHTML:documentTree]];
        }
        [_documentCache cacheObject:document forKey:url];
        [document autorelease];
    }
    
    return document;
}

- (EucCSSIntermediateDocument *)intermediateDocumentForIndexPoint:(EucBookPageIndexPoint *)indexPoint
{
    NSURL *url = [self documentURLForIndexPoint:indexPoint];
    if(url) {
        return [self _intermediateDocumentForURL:url];
    }
    return nil;
}

- (BOOL)fullBleedPageForIndexPoint:(EucBookPageIndexPoint *)indexPoint
{
    NSURL *url = [self documentURLForIndexPoint:indexPoint];
    return [url isEqual:_guideCoverItemURL];
}

- (void)setCacheDirectoryPath:(NSString *)path
{
    if(path != super.cacheDirectoryPath) {
        super.cacheDirectoryPath = path;
        [self _restorePersistedCachableDataIfPossible];
    }
}

- (NSString *)_persistedDataPath
{
    NSString *filename = [NSString stringWithFormat:@"v%luIndexIdToIndexPoint.keyedArchive", (unsigned long)[EucBookIndex indexVersion]];
    NSString *archivePath = [self.cacheDirectoryPath stringByAppendingPathComponent:filename];
    return archivePath;
}

- (void)persistCacheableData
{
    NSDictionary *idToIndexPoint = self.idToIndexPoint;
    if(idToIndexPoint.count) {
        // We save this with IDs as paths relative to our root rather than URLs
        // in case the book moves (i.e. when the UUID of the app is changed on
        // a backup/restore).
        NSMutableDictionary *toArchive = [[NSMutableDictionary alloc] initWithCapacity:idToIndexPoint.count];
        for(NSString *key in [idToIndexPoint keyEnumerator]) {
            NSURL *keyURL = [[NSURL alloc] initWithString:key];
            if(keyURL) {
                [toArchive setObject:[idToIndexPoint objectForKey:key]
                              forKey:[keyURL pathRelativeTo:_root]];
                [keyURL release];
            } else {
                [toArchive setObject:[idToIndexPoint objectForKey:key]
                              forKey:key];
            }
        }
        [toArchive setObject:[NSNumber numberWithFloat:_normalisingScaleFactor] forKey:@"___normalisingScaleFactor"];
        [NSKeyedArchiver archiveRootObject:toArchive 
                                    toFile:[self _persistedDataPath]];
        [toArchive release];
    }
}

- (void)_restorePersistedCachableDataIfPossible
{
    NSDictionary *fromArchive = [NSKeyedUnarchiver unarchiveObjectWithFile:[self _persistedDataPath]];
    if(fromArchive.count) {
        NSMutableDictionary *idToIndexPoint = [[NSMutableDictionary alloc] initWithCapacity:fromArchive.count];
        for(NSString *key in [fromArchive keyEnumerator]) {
            if([key isEqualToString:@"___normalisingScaleFactor"]) {
                _normalisingScaleFactor = [[fromArchive objectForKey:key] floatValue];
            } else {
                NSURL *fullKeyURL = [[NSURL alloc] initWithString:key relativeToURL:_root];
                if(fullKeyURL) {
                    [idToIndexPoint setObject:[fromArchive objectForKey:key]
                                       forKey:[fullKeyURL absoluteString]];
                    [fullKeyURL release];
                } else {
                    [idToIndexPoint setObject:[fromArchive objectForKey:key]
                                       forKey:key];
                }
            }
        }
		if (_idToIndexPoint) [_idToIndexPoint release];
        _idToIndexPoint = idToIndexPoint;
    }
}

@end