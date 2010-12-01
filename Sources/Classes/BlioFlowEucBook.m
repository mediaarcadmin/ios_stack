//
//  BlioFlowEucBook.m
//  BlioApp
//
//  Created by James Montgomerie on 19/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioFlowEucBook.h"
#import "BlioBook.h"
#import "BlioBookManager.h"
#import "BlioTextFlow.h"
#import "BlioTextFlowFlowTree.h"
#import "BlioTextFlowXAMLTree.h"
#import "BlioXPSProvider.h"

#import <libEucalyptus/EucBookPageIndexPoint.h>
#import <libEucalyptus/EucBookNavPoint.h>
#import <libEucalyptus/THPair.h>
#import <libEucalyptus/THRegex.h>

#import <CoreData/CoreData.h>

@interface BlioFlowEucBook ()

@property (nonatomic, assign) NSManagedObjectID *bookID;
@property (nonatomic, assign) BOOL fakeCover;
@property (nonatomic, retain) BlioTextFlow *textFlow;
@property (nonatomic, retain) id<BlioParagraphSource> paragraphSource;

@end

@implementation BlioFlowEucBook

@synthesize bookID;
@synthesize fakeCover;
@synthesize textFlow;
@synthesize paragraphSource;

- (id)initWithBookID:(NSManagedObjectID *)blioBookID
{
    BlioBookManager *bookManager = [BlioBookManager sharedBookManager];
    BlioBook *blioBook = [bookManager bookWithID:blioBookID];
    if(blioBook && (self = [super init])) {
        self.bookID = blioBookID;
        self.textFlow = [bookManager checkOutTextFlowForBookWithID:blioBookID];
        self.paragraphSource = [bookManager checkOutParagraphSourceForBookWithID:blioBookID];
        self.fakeCover = self.textFlow.flowTreeKind == BlioTextFlowFlowTreeKindFlow && [blioBook hasManifestValueForKey:BlioManifestCoverKey];
        
        self.title = blioBook.title;
        self.author = blioBook.author;
        self.etextNumber = nil;
    }
    
    return self;
}

- (void)dealloc
{
    self.paragraphSource = nil;
    [[BlioBookManager sharedBookManager] checkInParagraphSourceForBookWithID:self.bookID];
    self.textFlow = nil;
    [[BlioBookManager sharedBookManager] checkInTextFlowForBookWithID:self.bookID];
    
    BlioBook *aBook = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
    [aBook flushCaches];
    self.bookID = nil;
    
    [navPoints release];
    
    [super dealloc];
}

- (NSArray *)navPoints
{
    if(!navPoints) {
        NSMutableArray *buildNavPoints = [[NSMutableArray alloc] init];
       
        NSArray *tocEntries = self.textFlow.tableOfContents; 
        if(self.fakeCover) {
            [buildNavPoints addObject:[EucBookNavPoint navPointWithText:NSLocalizedString(@"Cover", "Name for 'chapter' title for the cover of the book")
                                                                   uuid:@"textflow:0"
                                                                  level:0]];
        }
        long index = 0;
        for(BlioTextFlowTOCEntry *tocEntry in tocEntries) {
            [buildNavPoints addObject:[EucBookNavPoint navPointWithText:tocEntry.name
                                                                   uuid:[NSString stringWithFormat:@"textflowTOCIndex:%ld", index]
                                                                  level:tocEntry.level]];
            ++index;
        }
        navPoints = buildNavPoints;
    }
    
    return navPoints;
}

- (BOOL)documentTreeIsHTML:(id<EucCSSDocumentTree>)documentTree
{
    if([documentTree isKindOfClass:[BlioTextFlowFlowTree class]] ||
       [documentTree isKindOfClass:[BlioTextFlowXAMLTree class]]) {
        return NO;
    } else {
        return [super documentTreeIsHTML:documentTree];
    }
}

- (NSArray *)baseCSSPathsForDocumentTree:(id<EucCSSDocumentTree>)documentTree
{
    if([documentTree isKindOfClass:[BlioTextFlowFlowTree class]]) {
        return [NSArray arrayWithObject:[[NSBundle mainBundle] pathForResource:@"TextFlowFlow" ofType:@"css"]];
    } else if([documentTree isKindOfClass:[BlioTextFlowXAMLTree class]]) {
        return [NSArray arrayWithObject:[[NSBundle mainBundle] pathForResource:@"TextFlowXAML" ofType:@"css"]];
    } else {
        NSMutableArray *ret = [[[super baseCSSPathsForDocumentTree:documentTree] mutableCopy] autorelease];
        [ret addObject:[[NSBundle mainBundle] pathForResource:@"ePubBaseOverrides" ofType:@"css"]];
        return ret;
    }
}

- (NSArray *)userCSSPathsForDocumentTree:(id<EucCSSDocumentTree>)documentTree
{
    if([documentTree isKindOfClass:[BlioTextFlowFlowTree class]]) {
        return nil;
    } else if([documentTree isKindOfClass:[BlioTextFlowXAMLTree class]]) {
        return [NSArray arrayWithObject:[[NSBundle mainBundle] pathForResource:@"TextFlowXAMLOverrides" ofType:@"css"]];
    } else {
        return [super userCSSPathsForDocumentTree:documentTree];
    }
}

- (BOOL)fullBleedPageForIndexPoint:(EucBookPageIndexPoint *)indexPoint
{
    return indexPoint.source == 0 && 
                (self.fakeCover || 
                 (indexPoint.block == 0 && indexPoint.word == 0 && indexPoint.element == 0)
                );
}

- (NSData *)dataForURL:(NSURL *)url
{
    if([[url absoluteString] isEqualToString:@"textflow:coverimage"]) {
        return [[[BlioBookManager sharedBookManager] bookWithID:self.bookID] manifestDataForKey:BlioManifestCoverKey];
    } else if([[url scheme] isEqualToString:@"textflow"]) {
        BlioXPSProvider *provider = [[BlioBookManager sharedBookManager] checkOutXPSProviderForBookWithID:self.bookID];
        NSData *ret = [provider dataForComponentAtPath:[[url absoluteURL] path]];
        [[BlioBookManager sharedBookManager] checkInXPSProviderForBookWithID:self.bookID];
        return ret;
    }
    return [super dataForURL:url];
}

- (id<EucCSSDocumentTree>)documentTreeForURL:(NSURL *)url
{
    id<EucCSSDocumentTree> tree = nil;
    NSString *indexString = [[[url absoluteString] matchPOSIXRegex:@"^textflow:(.*)$"] match:1];
    if(indexString) {
        NSUInteger section = [indexString integerValue];
        if(self.fakeCover) {
            if(section == 0) {
                NSURL *coverHTMLFile = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"TextFlowCover" ofType:@"xhtml"]];
                tree = [super documentTreeForURL:coverHTMLFile];
            } else {
                --section;
            }
        }
        if(!tree) {
            tree = [self.textFlow flowTreeForFlowIndex:section];
            if(!tree) {
                tree = [self.textFlow xamlTreeForFlowIndex:section];
            }
        }
    }
    return tree;
}

- (NSURL *)documentURLForIndexPoint:(EucBookPageIndexPoint *)point
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"textflow:%ld", (long)point.source]];
}

- (float *)indexSourceScaleFactors
{
    if(!_indexSourceScaleFactors) {
        NSUInteger flowCount = textFlow.flowReferences.count + 1;
        
        // TODO: make this actually based on section length for accurate pagination progress.
        
        /*size_t *sizes = malloc(sectionCount * sizeof(size_t));;
        size_t total = 0;
        
        struct stat statResult;
        if(stat([[NSBundle mainBundle] pathForResource:@"TextFlowCover" ofType:@"xhtml"].fileSystemRepresentation, &statResult) == 0) {
            sizes[0]= statResult.st_size;
            total += sizes[0];
        }
        for(NSUInteger i = 0; i < sectionCount - 1; ++i) {
            sizes[i+1] = [textFlow sizeOfSectionWithIndex:i];
            total += sizes[i+1];
        }
              
        _indexSourceScaleFactors = malloc(sectionCount * sizeof(float));
        
        for(NSUInteger i = 0; i < sectionCount; ++i) {  
            _indexSourceScaleFactors[i] = (float)sizes[i] / (float)total;
        }
        
        free(sizes);*/
        
        _indexSourceScaleFactors = malloc(flowCount * sizeof(float));
        for(int i = 0; i < flowCount; ++i) {
            _indexSourceScaleFactors[i] = 1.0f / flowCount;
        }
    }
    
    return _indexSourceScaleFactors;
}

- (NSDictionary *)buildIdToIndexPoint
{
    NSArray *myNavPoints = self.navPoints;
    NSMutableDictionary *buildIdToIndexPoint = [[NSMutableDictionary alloc] initWithCapacity:myNavPoints.count];
    for(THPair *navPoint in myNavPoints) {
        NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
        
        EucBookPageIndexPoint *indexPoint = nil;
        NSString *identifier = navPoint.second;
        NSString *tocIndexString = [[identifier matchPOSIXRegex:@"^textflowTOCIndex:([[:digit:]]+)$"] match:1];
        if(tocIndexString) {
            BlioTextFlowTOCEntry *entry = [self.textFlow.tableOfContents objectAtIndex:[tocIndexString integerValue]];
            NSUInteger layoutPageIndex = entry.startPage;
            NSUInteger flowReferenceIndex = 0;
            for(BlioTextFlowFlowReference *flowReference in self.textFlow.flowReferences) {
                if(flowReference.startPage == layoutPageIndex) {
                    indexPoint = [[[EucBookPageIndexPoint alloc] init] autorelease];
                    indexPoint.source = flowReferenceIndex;
                    break;
                }
                ++flowReferenceIndex;
            }
            if(!indexPoint) {
                BlioBookmarkPoint *point = [[[BlioBookmarkPoint alloc] init] autorelease];
                point.layoutPage = layoutPageIndex + 1;
                indexPoint = [self bookPageIndexPointFromBookmarkPoint:point];
            }
        } else {
            NSString *indexString = [[identifier matchPOSIXRegex:@"^textflow:([[:digit:]]+)$"] match:1];
            if(indexString) {
                indexPoint = [[[EucBookPageIndexPoint alloc] init] autorelease];
                indexPoint.source = [indexString integerValue];
            }
        }
        if(indexPoint) {
            [buildIdToIndexPoint setObject:indexPoint forKey:identifier];
        }
        
        [innerPool drain];
    }
    [buildIdToIndexPoint addEntriesFromDictionary:super.buildIdToIndexPoint];

    return [buildIdToIndexPoint autorelease];
}
    

- (BlioBookmarkPoint *)bookmarkPointFromBookPageIndexPoint:(EucBookPageIndexPoint *)indexPoint
{
    BlioBookmarkPoint *ret = nil;
    
    EucBookPageIndexPoint *eucIndexPoint = [indexPoint copy];
    
    // EucIndexPoint words start with word 0 == before the first word,
    // but Blio thinks that the first word is at 0.  This is a bit lossy,
    // but there's not much else we can do.
    if(eucIndexPoint.word == 0) {
        eucIndexPoint.element = 0;
    } else {
        eucIndexPoint.word -= 1;
    }
    
    if(eucIndexPoint.source == 0 && self.fakeCover) {
        ret = [[BlioBookmarkPoint alloc] init];
        // This is the cover section.
        ret.layoutPage = 1;
        ret.blockOffset = 0;
        ret.wordOffset = 0;
        ret.elementOffset = 0;
    } else if(self.fakeCover) {
        eucIndexPoint.source--;
    }
    
    if(!ret) {
        ret = [[BlioBookmarkPoint alloc] init];
        
        NSUInteger indexes[2] = { eucIndexPoint.source , [EucCSSIntermediateDocument documentTreeNodeKeyForKey:eucIndexPoint.block]};
        NSIndexPath *indexPath = [[NSIndexPath alloc] initWithIndexes:indexes length:2];                         
        BlioBookmarkPoint *bookmarkPoint = [self.paragraphSource bookmarkPointFromParagraphID:indexPath wordOffset:eucIndexPoint.word];
        [indexPath release];
        
        if(bookmarkPoint) {
            ret.layoutPage = bookmarkPoint.layoutPage;
            ret.blockOffset = bookmarkPoint.blockOffset;
            ret.wordOffset = bookmarkPoint.wordOffset;
            ret.elementOffset = eucIndexPoint.element;
        }
    }

    [eucIndexPoint release];
    
    return [ret autorelease];    
}

- (EucBookPageIndexPoint *)bookPageIndexPointFromBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    if(!bookmarkPoint) {
        return nil;   
    } else {
        EucBookPageIndexPoint *eucIndexPoint = [[EucBookPageIndexPoint alloc] init];
        
        NSIndexPath *paragraphID = nil;
        uint32_t wordOffset = 0;
            
        [self.paragraphSource bookmarkPoint:bookmarkPoint
                              toParagraphID:&paragraphID 
                                 wordOffset:&wordOffset];
        
        eucIndexPoint.source = [paragraphID indexAtPosition:0];
        eucIndexPoint.block = [EucCSSIntermediateDocument keyForDocumentTreeNodeKey:[paragraphID indexAtPosition:1]];
        eucIndexPoint.word = wordOffset;
        eucIndexPoint.element = bookmarkPoint.elementOffset;

        if(self.fakeCover) {
            eucIndexPoint.source++;
        }        
        
        // EucIndexPoint words start with word 0 == before the first word,
        // but Blio thinks that the first word is at 0.  This is a bit lossy,
        // but there's not much else we can do.    
        eucIndexPoint.word += 1;
        
        return [eucIndexPoint autorelease];  
    }
}

@end
