//
//  BlioLayoutPDFDataSource.h
//  BlioApp
//
//  Created by matt on 06/10/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioLayoutDataSource.h"

@interface BlioLayoutPDFDataSource : NSObject<BlioLayoutDataSource> {
    NSData *data;
    NSInteger pageCount;
    CGPDFDocumentRef pdf;
    NSLock *pdfLock;
}

@property (nonatomic, retain) NSData *data;

- (id)initWithPath:(NSString *)aPath;

@end
