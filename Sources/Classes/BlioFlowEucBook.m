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
        self.title = blioBook.title;
        self.author = blioBook.author;
        self.path = blioBook.bookCacheDirectory;
        self.etextNumber = nil;
        self.coverPath = [blioBook.bookCacheDirectory stringByAppendingPathComponent:blioBook.coverFilename];
        
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
    if(self.coverPath) {
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
    return indexPoint.source == 0 && self.coverPath != nil;
}

- (NSData *)dataForURL:(NSURL *)url
{
    if([[url absoluteString] isEqualToString:@"textflow:coverimage"]) {
        return [NSData dataWithContentsOfMappedFile:self.coverPath];
    }
    return [super dataForURL:url];
}

- (id<EucCSSDocumentTree>)documentTreeForURL:(NSURL *)url
{
    id<EucCSSDocumentTree> tree = nil;
    NSString *indexString = [[[url absoluteString] matchPOSIXRegex:@"^textflow:(.*)$"] match:1];
    if(indexString) {
        NSUInteger section = [indexString integerValue];
        if(self.coverPath) {
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

@end
