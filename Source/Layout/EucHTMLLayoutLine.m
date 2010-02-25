//
//  EucHTMLLayoutLine.m
//  LibCSSTest
//
//  Created by James Montgomerie on 12/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucHTMLLayoutLine.h"
#import "EucHTMLDocumentNode.h"
#import "EucHTMLLayoutDocumentRun.h"
#import "EucHTMLLayoutDocumentRun_Package.h"
#import "THLog.h"

@implementation EucHTMLLayoutLine

@synthesize documentRun = _documentRun;

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
    
    id spaceMarker = [EucHTMLLayoutDocumentRun singleSpaceMarker];
    Class NSStringClass = [NSString class];
    
    size_t componentsCount = _documentRun.componentsCount;
    id *components = _documentRun.components;
    EucHTMLLayoutDocumentRunComponentInfo *componentInfos = _documentRun.componentInfos;
    
    uint32_t startComponentOffset = _documentRun.wordToComponent[_startPoint.word] + _startPoint.element;
    for(uint32_t i = startComponentOffset;
        i < componentsCount &&
        !(componentInfos[i].point.word == _endPoint.word && componentInfos[i].point.element == _endPoint.element); 
        ++i) {
        id component = components[i];
        EucHTMLLayoutDocumentRunComponentInfo *info =  componentInfos + i;
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
