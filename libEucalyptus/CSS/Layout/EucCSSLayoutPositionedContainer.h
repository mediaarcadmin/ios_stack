//
//  EucCSSLayoutPositionedContainer.h
//  libEucalyptus
//
//  Created by James Montgomerie on 22/07/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif

@interface EucCSSLayoutPositionedContainer : NSObject { 
    EucCSSLayoutPositionedContainer *_parent;
    CGRect _frame;
    NSMutableArray *_children;
}

@property (nonatomic, assign) EucCSSLayoutPositionedContainer *parent;
@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign, readonly) CGRect contentRect;
@property (nonatomic, assign, readonly) CGRect contentBounds;
@property (nonatomic, retain) NSMutableArray *children;

- (CGRect)convertRect:(CGRect)rect toContainer:(EucCSSLayoutPositionedContainer *)container;
- (CGRect)absoluteFrame;

@end
