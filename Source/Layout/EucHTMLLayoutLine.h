//
//  EucHTMLLayoutLine.h
//  LibCSSTest
//
//  Created by James Montgomerie on 12/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucHTMLLayoutDocumentRun.h"

@class EucHTMLLayoutDocumentRun;

@interface EucHTMLLayoutLine : NSObject {
    EucHTMLLayoutDocumentRun *_documentRun;
    
    EucHTMLLayoutDocumentRunPoint _startPoint;
    EucHTMLLayoutDocumentRunPoint _endPoint;

    CGPoint _origin; 
    CGSize _size;
    
    CGFloat _baseline;
    CGFloat _componentWidth;
    
    CGFloat _indent;
    uint8_t _align;
}

@property (nonatomic, retain) EucHTMLLayoutDocumentRun *documentRun;

@property (nonatomic, assign) EucHTMLLayoutDocumentRunPoint startPoint;
@property (nonatomic, assign) EucHTMLLayoutDocumentRunPoint endPoint;

@property (nonatomic, assign) CGPoint origin;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign, readonly) CGRect frame;

@property (nonatomic, assign) CGFloat indent;
@property (nonatomic, assign) uint8_t align;

@property (nonatomic, readonly) CGFloat componentWidth;

- (void)sizeToFitInWidth:(CGFloat)width;

@end
