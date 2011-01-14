//
//  EucCSSLayoutSizedEntity.h
//  libEucalyptus
//
//  Created by James Montgomerie on 04/01/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif

@interface EucCSSLayoutSizedEntity : NSObject {
    CGFloat _scaleFactor;
    EucCSSLayoutSizedEntity *_parent;
}

- (id)initWithScaleFactor:(CGFloat)scaleFactor;

@property (nonatomic, assign, readonly) CGFloat scaleFactor;
@property (nonatomic, assign) EucCSSLayoutSizedEntity *parent;

// Overridable - defaults are for 0-sized empty object.

@property (nonatomic, assign, readonly) CGFloat minWidth;
@property (nonatomic, assign, readonly) CGFloat maxWidth;

@end
