//
//  EucCSSLayoutLine.m
//  LibCSSTest
//
//  Created by James Montgomerie on 12/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutLine.h"
#import "EucCSSIntermediateDocumentNode.h"
#import "EucCSSLayoutPositionedRun.h"
#import "EucCSSLayoutDocumentRun.h"
#import "EucCSSLayoutDocumentRun_Package.h"
#import "THLog.h"

@implementation EucCSSLayoutLine

@synthesize containingRun = _positionedRun;

@synthesize startPoint = _startPoint;
@synthesize endPoint = _endPoint;

@synthesize origin = _origin;
@synthesize size = _size;

@synthesize componentWidth = _componentWidth;

@synthesize indent = _indent;
@synthesize align = _align;

- (void)sizeToFitInWidth:(CGFloat)width;
{
    CGFloat maxAscender = 0;
    CGFloat maxDescenderAndLineHeightAddition = 0;
    
    id spaceMarker = [EucCSSLayoutDocumentRun singleSpaceMarker];
    Class NSStringClass = [NSString class];
    
    EucCSSLayoutDocumentRun *documentRun = self.containingRun.documentRun;
    size_t componentsCount = documentRun.componentsCount;
    id *components = documentRun.components;
    EucCSSLayoutDocumentRunComponentInfo *componentInfos = documentRun.componentInfos;
    
    uint32_t startComponentOffset = documentRun.wordToComponent[_startPoint.word] + _startPoint.element;
    for(uint32_t i = startComponentOffset;
        i < componentsCount &&
        !(componentInfos[i].point.word == _endPoint.word && componentInfos[i].point.element == _endPoint.element); 
        ++i) {
        id component = components[i];
        EucCSSLayoutDocumentRunComponentInfo *info =  componentInfos + i;
        BOOL isWord = [component isKindOfClass:NSStringClass];
        if(isWord ||
           component == spaceMarker) {
            CGFloat ascender = info->ascender;
            if(ascender > maxAscender) {
                maxAscender = ascender;
            }
            CGFloat descenderAndLineHeightAddition = info->lineHeight - info->ascender;
            if(descenderAndLineHeightAddition > maxDescenderAndLineHeightAddition) {
                maxDescenderAndLineHeightAddition = descenderAndLineHeightAddition;
            }
        }
        _componentWidth += info->width;
    }

    _baseline = maxAscender;
    _size = CGSizeMake(width, maxAscender + maxDescenderAndLineHeightAddition);
    
    // TODO: Properly respect line height.
    // This is a hack to make newlines work...
    if(_size.height == 0) {
        _size.height = 16;
    }
}

- (CGRect)frame
{
    return CGRectMake(_origin.x, _origin.y, _size.width, _size.height);
}

@end
