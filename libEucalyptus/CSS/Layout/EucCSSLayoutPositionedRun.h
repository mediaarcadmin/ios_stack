//
//  EucCSSLayoutPositionedRun.h
//  LibCSSTest
//
//  Created by James Montgomerie on 13/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif

@class EucCSSLayoutDocumentRun, EucCSSLayoutPositionedBlock;

@interface EucCSSLayoutPositionedRun : NSObject {
    EucCSSLayoutDocumentRun *_documentRun;
    EucCSSLayoutPositionedBlock *_containingBlock;
    NSArray *_lines;
    CGRect _frame;
}

@property (nonatomic, retain, readonly) EucCSSLayoutDocumentRun *documentRun;
@property (nonatomic, assign) EucCSSLayoutPositionedBlock *containingBlock;
@property (nonatomic, retain) NSArray *lines;
@property (nonatomic, assign) CGRect frame;

- (id)initWithDocumentRun:(EucCSSLayoutDocumentRun *)documentRun;

@end
