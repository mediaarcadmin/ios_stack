//
//  BlioLayoutPDFDataSource.h
//  BlioApp
//
//  Created by matt on 06/10/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioLayoutDataSource.h"
#import <libEucalyptus/EucBookContentsTableViewController.h>

@interface BlioLayoutPDFDataSource : NSObject<BlioLayoutDataSource, EucBookContentsTableViewControllerDataSource> {
    NSData *data;
    NSInteger pageCount;
    CGPDFDocumentRef pdf;
    NSLock *pdfLock;
	NSArray *tableOfContents;
	NSDictionary *namesDictionary;
}

@property (nonatomic, retain) NSData *data;
@property (nonatomic, retain, readonly) NSArray *tableOfContents;
@property (nonatomic, retain, readonly) NSDictionary *namesDictionary;

- (id)initWithPath:(NSString *)aPath;

@end
