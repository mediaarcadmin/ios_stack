//
//  EucCSSLayoutLine.h
//  LibCSSTest
//
//  Created by James Montgomerie on 12/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucCSSLayoutDocumentRun.h"

@class EucCSSLayoutDocumentRun, EucCSSLayoutPositionedRun;

@interface EucCSSLayoutLine : NSObject {
    EucCSSLayoutPositionedRun *_positionedRun;
    
    EucCSSLayoutDocumentRunPoint _startPoint;
    EucCSSLayoutDocumentRunPoint _endPoint;

    CGPoint _origin; 
    CGSize _size;
    
    CGFloat _baseline;
    CGFloat _componentWidth;
    
    CGFloat _indent;
    uint8_t _align;
}

@property (nonatomic, assign) EucCSSLayoutPositionedRun *containingRun;

@property (nonatomic, assign) EucCSSLayoutDocumentRunPoint startPoint;
@property (nonatomic, assign) EucCSSLayoutDocumentRunPoint endPoint;

@property (nonatomic, assign) CGPoint origin;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign, readonly) CGRect frame;

@property (nonatomic, assign) CGFloat indent;
@property (nonatomic, assign) CGFloat baseline;

@property (nonatomic, assign) uint8_t align;

@property (nonatomic, readonly) CGFloat componentWidth;

- (void)sizeToFitInWidth:(CGFloat)width;

@end
