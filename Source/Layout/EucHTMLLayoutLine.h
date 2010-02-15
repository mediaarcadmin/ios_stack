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
    
    uint32_t _startComponentOffset;
    uint32_t _startHyphenOffset;
    
    uint32_t _endComponentOffset;
    uint32_t _endHyphenOffset;
    
    CGPoint _origin; 
    CGSize _size;
    
    CGFloat _baseline;
}

@property (nonatomic, retain) EucHTMLLayoutDocumentRun *documentRun;

@property (nonatomic, assign) uint32_t startComponentOffset;
@property (nonatomic, assign) uint32_t startHyphenOffset;
@property (nonatomic, assign) uint32_t endComponentOffset;
@property (nonatomic, assign) uint32_t endHyphenOffset;

@property (nonatomic, assign) CGPoint origin;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign, readonly) CGRect frame;

@property (nonatomic, readonly) id *components;
@property (nonatomic, readonly) EucHTMLLayoutDocumentRunComponentInfo *componentInfos;
@property (nonatomic, readonly) uint32_t componentCount;

- (void)sizeToFitInWidth:(CGFloat)width;

@end
