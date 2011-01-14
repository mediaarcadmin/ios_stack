//
//  EucCSSLayoutSizedContainer.h
//  libEucalyptus
//
//  Created by James Montgomerie on 11/01/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif

#import <Foundation/Foundation.h>

#import "EucCSSLayoutSizedEntity.h"

@class EucCSSLayoutPositionedContainer, EucCSSLayouter;

@interface EucCSSLayoutSizedContainer : EucCSSLayoutSizedEntity {
    NSMutableArray *_children;
}

@property (nonatomic, retain, readonly) NSArray *children;

- (void)addChild:(EucCSSLayoutSizedEntity *)child;
- (void)positionChildrenInContainer:(EucCSSLayoutPositionedContainer *)container
                      usingLayouter:(EucCSSLayouter *)layouter;

@end
