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

#import <libEucalyptus/EucBookPageIndexPoint.h>
#import <libEucalyptus/THPair.h>
#import <libEucalyptus/THRegex.h>

#import <CoreData/CoreData.h>
#import <sys/stat.h>

@interface BlioFlowEucBook ()

@property (nonatomic, assign) NSManagedObjectID *bookID;
@property (nonatomic, assign) BOOL hasCover;
@property (nonatomic, retain) BlioTextFlow *textFlow;

@end

@implementation BlioFlowEucBook

@synthesize bookID;
@synthesize hasCover;
@synthesize textFlow;

- (id)initWithBookID:(NSManagedObjectID *)blioBookID
{
    if((self = [super init])) {
        self.bookID = blioBookID;
        BlioBookManager *bookManager = [BlioBookManager sharedBookManager];
        BlioBook *blioBook = [bookManager bookWithID:blioBookID];
        self.textFlow = [bookManager checkOutTextFlowForBookWithID:blioBookID];
        self.hasCover = [blioBook hasManifestValueForKey:@"coverFilename"];
        
        self.title = blioBook.title;
        self.author = blioBook.author;
        self.path = blioBook.bookCacheDirectory;
        self.etextNumber = nil;
    }
    
    return self;
}

- (void)dealloc
{
    self.textFlow = nil;
    [[BlioBookManager sharedBookManager] checkInTextFlowForBookWithID:self.bookID];
    self.bookID = nil;
    
    [super dealloc];
}

- (NSArray *)navPoints
{
    NSMutableArray *navPoints = [NSMutableArray array];
    
    NSArray *sections = self.textFlow.sections; 
    long index = 0;
    if(self.hasCover) {
        [navPoints addPairWithFirst:NSLocalizedString(@"Cover", "Name for 'chapter' title for the cover of the book")
                             second:[NSString stringWithFormat:@"textflow:$ld", (long)index]];
        ++index;
    }
    for(BlioTextFlowSection *section in sections) {
        [navPoints addPairWithFirst:section.name
                             second:[NSString stringWithFormat:@"textflow:%ld", (long)index]];
        ++index;
    }
    
    return navPoints;
}

- (NSString *)baseCSSPathForDocumentTree:(id<EucCSSDocumentTree>)documentTree
{
    if([documentTree isKindOfClass:[BlioTextFlowFlowTree class]]) {
        return [[NSBundle mainBundle] pathForResource:@"TextFlow" ofType:@"css"];
    } else {
        return [super baseCSSPathForDocumentTree:documentTree];
    }
}

- (BOOL)fullBleedPageForIndexPoint:(EucBookPageIndexPoint *)indexPoint
{
    return indexPoint.source == 0 && self.hasCover;
}

- (NSData *)dataForURL:(NSURL *)url
{
    if([[url absoluteString] isEqualToString:@"textflow:coverimage"]) {
        return [[[BlioBookManager sharedBookManager] bookWithID:self.bookID] manifestDataForKey:@"coverFilename"];
    }
    return [super dataForURL:url];
}

- (id<EucCSSDocumentTree>)documentTreeForURL:(NSURL *)url
{
    id<EucCSSDocumentTree> tree = nil;
    NSString *indexString = [[[url absoluteString] matchPOSIXRegex:@"^textflow:(.*)$"] match:1];
    if(indexString) {
        NSUInteger section = [indexString integerValue];
        if(self.hasCover) {
            if(section == 0) {
                NSURL *coverHTMLFile = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"TextFlowCover" ofType:@"xhtml"]];
                tree = [super documentTreeForURL:coverHTMLFile];
            } else {
                --section;
            }
        }
        if(!tree) {
            tree = [self.textFlow flowTreeForSectionIndex:section];
        }
    }
    return tree;
}

- (NSURL *)documentURLForIndexPoint:(EucBookPageIndexPoint *)point
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"textflow:%ld", (long)point.source]];
}

- (EucBookPageIndexPoint *)indexPointForId:(NSString *)identifier
{
    EucBookPageIndexPoint *indexPoint = [[EucBookPageIndexPoint alloc] init];
    
    NSString *indexString = [[identifier matchPOSIXRegex:@"^textflow:(.*)$"] match:1];
    if(indexString) {
        indexPoint.source = [indexString integerValue];
    }
    
    return [indexPoint autorelease];
}

- (float *)indexSourceScaleFactors
{
    if(!_indexSourceScaleFactors) {
        NSUInteger sectionCount = textFlow.sections.count + 1;
        size_t *sizes = malloc(sectionCount * sizeof(size_t));;
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
        
        free(sizes);
    }
    
    return _indexSourceScaleFactors;
}

- (void)persistCacheableData
{
    // Superclass persists the ePub anchors here, but we don't have any 
    // (ePub uses them in indexPointForId:, but we can compute that directly)
    // so we do nothing.
}

@end
