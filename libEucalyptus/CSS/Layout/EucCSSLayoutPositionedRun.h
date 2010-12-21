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

@class EucCSSLayoutRun, EucCSSLayoutPositionedBlock;

@interface EucCSSLayoutPositionedRun : EucCSSLayoutPositionedContainer {
    EucCSSLayoutRun *_Run;
}

@property (nonatomic, retain, readonly) EucCSSLayoutRun *Run;

- (id)initWithRun:(EucCSSLayoutRun *)Run;

@end
