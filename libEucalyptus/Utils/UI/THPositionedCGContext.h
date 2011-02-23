//
//  THPositionedCGContext.h
//  libEucalyptus
//
//  Created by James Montgomerie on 23/02/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif

@interface THPositionedCGContext : NSObject {
    CGContextRef _CGContext;
    CGPoint _origin;
    id _backing;
}

- (id)initWithCGContext:(CGContextRef)CGContext backing:(id)backing;
- (id)initWithCGContext:(CGContextRef)CGContext origin:(CGPoint)origin backing:(id)backing;

@property (nonatomic, retain) __attribute__((NSObject)) CGContextRef CGContext;
@property (nonatomic, assign) CGPoint origin;
@property (nonatomic, retain) id backing;

@end
