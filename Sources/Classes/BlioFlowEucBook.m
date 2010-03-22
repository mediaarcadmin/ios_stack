//
//  BlioFlowEucBook.m
//  BlioApp
//
//  Created by James Montgomerie on 19/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioFlowEucBook.h"
#import "BlioMockBook.h"
#import "BlioTextFlow.h"
#import "BlioTextFlowFlowTree.h"

#import <libEucalyptus/EucBookPageIndexPoint.h>
#import <libEucalyptus/THPair.h>
#import <libEucalyptus/THRegex.h>

@implementation BlioFlowEucBook

@synthesize textFlow;

- (id)initWithBlioBook:(BlioMockBook *)blioBook;
{
    if((self = [super init])) {
        textFlow = [blioBook.textFlow retain];
        self.title = [blioBook.title retain];
        self.author = [blioBook.author retain];
        self.path = [blioBook.bookCacheDirectory retain];
        self.etextNumber = nil;
        
        self.persistsPositionAutomatically = NO;
    }
    
    return self;
}

- (void)dealloc
{
    [textFlow release];
    [super dealloc];
}

- (NSArray *)navPoints
{
    NSMutableArray *navPoints = [NSMutableArray array];
    
    NSArray *sections = self.textFlow.sections; 
    long index = 0;
    for(BlioTextFlowSection *section in sections) {
        [navPoints addPairWithFirst:section.name
                             second:[NSString stringWithFormat:@"textflow:%ld", (long)index]];
        ++index;
    }
    
    return navPoints;
}

- (BOOL)documentsAreHTML
{
    return NO;
}

- (NSString *)baseCSSPath
{
    return [[NSBundle mainBundle] pathForResource:@"TextFlow" ofType:@"css"];
}

- (id<EucCSSDocumentTree>)documentTreeForURL:(NSURL *)url
{
    BlioTextFlowFlowTree *flowTree = nil;
    NSString *indexString = [[[url absoluteString] matchPOSIXRegex:@"^textflow:([[:digit:]]+)$"] match:1];
    if(indexString) {
        flowTree = [self.textFlow flowTreeForSectionIndex:[indexString integerValue]];
    }
    return flowTree;
}

- (NSURL *)documentURLForIndexPoint:(EucBookPageIndexPoint *)point
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"textflow:%ld", (long)point.source]];
}

- (EucBookPageIndexPoint *)indexPointForId:(NSString *)identifier
{
    EucBookPageIndexPoint *indexPoint = [[EucBookPageIndexPoint alloc] init];
    
    NSString *indexString = [[identifier matchPOSIXRegex:@"^textflow:([[:digit:]]+)$"] match:1];
    if(indexString) {
        indexPoint.source = [indexString integerValue];
    }
    
    return [indexPoint autorelease];
}

@end
