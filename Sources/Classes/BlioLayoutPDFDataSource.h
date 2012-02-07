//
//  BlioLayoutPDFDataSource.h
//  BlioApp
//
//  Created by matt on 06/10/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioLayoutDataSource.h"
#import "BlioPDFResourceDataSource.h"
#import <libEucalyptus/EucBookContentsTableViewController.h>

#define kPDFPageBlocksCacheCapacity 5

@class KNFBTOCEntry;

@interface BlioLayoutPDFDataSource : NSObject<BlioLayoutDataSource, EucBookContentsTableViewControllerDataSource, BlioPDFResourceDataSource> {
    NSData *data;
    NSInteger pageCount;
    CGPDFDocumentRef pdf;
    NSLock *pdfLock;
	NSArray *tableOfContents;
	NSDictionary *namesDictionary;
    NSInteger pageIndexCache[kPDFPageBlocksCacheCapacity];
    NSArray *pageBlocksCache[kPDFPageBlocksCacheCapacity];
    NSLock *pageBlocksCacheLock;
}

@property (nonatomic, retain) NSData *data;
@property (nonatomic, retain, readonly) NSArray *tableOfContents;
@property (nonatomic, retain, readonly) NSDictionary *namesDictionary;

- (id)initWithPath:(NSString *)aPath;
- (KNFBTOCEntry *)tocEntryForSectionUuid:(NSString *)sectionUuid;
- (NSString *)sectionUuidForPageIndex:(NSUInteger)aPageIndex;
- (NSArray *)blocksForPageAtIndex:(NSInteger)pageIndex includingFolioBlocks:(BOOL)includingFolioBlocks;

@end
