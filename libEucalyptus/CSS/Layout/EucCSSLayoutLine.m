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
@synthesize baseline = _baseline;

@synthesize align = _align;

- (void)sizeToFitInWidth:(CGFloat)width;
{
    EucCSSLayoutDocumentRun *documentRun = self.containingRun.documentRun;

    CGFloat lineBoxHeight = 0;
    CGFloat currentBaseline = 0;
    
    size_t componentsCount = documentRun.componentsCount;
    uint32_t startComponentOffset = documentRun.wordToComponent[_startPoint.word] + _startPoint.element;

    EucCSSIntermediateDocumentNode *currentDocumentNode = nil;
    id *component;
    EucCSSLayoutDocumentRunComponentInfo *info;
    uint32_t i;
    for(i = startComponentOffset, component = &(documentRun.components[i]), info = &(documentRun.componentInfos[i]);
        i < componentsCount && !(info->point.word == _endPoint.word && info->point.element == _endPoint.element); 
        ++i, ++component, ++info) {
        if(info->documentNode != currentDocumentNode) {
            CGFloat emBoxHeight = info->pointSize;
            CGFloat halfLeading = (info->lineHeight - emBoxHeight) * 0.5f;
            
            CGFloat inlineBoxHeight = info->lineHeight;
            
            CGFloat baseline = info->ascender + halfLeading;
            CGFloat descenderAndLineHeightAddition = inlineBoxHeight - baseline;
            if(baseline > currentBaseline) {
                currentBaseline = baseline;
            }
            CGFloat baselineAdjustedLineHeight = currentBaseline + descenderAndLineHeightAddition;
            if(baselineAdjustedLineHeight > lineBoxHeight) {
                lineBoxHeight = baselineAdjustedLineHeight;
            }
        }
        _componentWidth += info->width;
    }
    
    _baseline = currentBaseline;
    _size = CGSizeMake(width, lineBoxHeight);
}

- (CGRect)frame
{
    return CGRectMake(_origin.x, _origin.y, _size.width, _size.height);
}

@end
