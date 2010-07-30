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

#import "EucCSSLayoutPositionedContainer.h"

@class EucCSSLayoutDocumentRun, EucCSSLayoutPositionedBlock;

@interface EucCSSLayoutPositionedRun : EucCSSLayoutPositionedContainer {
    EucCSSLayoutDocumentRun *_documentRun;
}

@property (nonatomic, retain, readonly) EucCSSLayoutDocumentRun *documentRun;

- (id)initWithDocumentRun:(EucCSSLayoutDocumentRun *)documentRun;

@end
