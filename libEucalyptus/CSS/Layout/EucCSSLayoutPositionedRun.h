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

@class EucCSSLayoutSizedRun, EucCSSLayoutPositionedBlock;

@interface EucCSSLayoutPositionedRun : EucCSSLayoutPositionedContainer {
    EucCSSLayoutSizedRun *_sizedRun;
}

@property (nonatomic, retain, readonly) EucCSSLayoutSizedRun *sizedRun;

- (id)initWithSizedRun:(EucCSSLayoutSizedRun *)sizedRun;

@end
