//
//  EucCSSLayoutLine.m
//  LibCSSTest
//
//  Created by James Montgomerie on 12/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EucCSSLayoutLine.h"
#import "EucCSSIntermediateDocumentNode.h"
#import "EucCSSLayoutPositionedRun.h"
#import "EucCSSLayoutDocumentRun.h"
#import "EucCSSLayoutDocumentRun_Package.h"
#import "THLog.h"

#import <libcss/libcss.h>

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

- (void)dealloc
{    
    EucCSSLayoutLineRenderItem *renderItem = _renderItems;
    EucCSSLayoutLineRenderItem *renderItemEnd = _renderItems + _renderItemCount;
    for(; renderItem < renderItemEnd; ++renderItem) {
        [renderItem->item release];
        [renderItem->stringRenderer release];
        if(renderItem->altText) {
            [renderItem->altText release];   
        }
    }
    free(_renderItems);
    
    [super dealloc];
}

- (void)sizeToFitInWidth:(CGFloat)width;
{
    EucCSSLayoutDocumentRun *documentRun = self.containingRun.documentRun;

    CGFloat lineBoxHeight = 0;
    CGFloat currentBaseline = 0;
    
    size_t componentsCount = documentRun.componentsCount;
    uint32_t startComponentOffset = [documentRun pointToComponentOffset:_startPoint];
    uint32_t lastComponentOffset = [documentRun pointToComponentOffset:_endPoint] - 1;
    EucCSSLayoutDocumentRunComponentInfo *componentInfos = &(documentRun.componentInfos[startComponentOffset]);

    EucCSSIntermediateDocumentNode *currentDocumentNode = nil;
    uint32_t i;
    EucCSSLayoutDocumentRunComponentInfo *info;
    for(i = startComponentOffset, info = componentInfos;
        i < componentsCount && i <= lastComponentOffset; 
        ++i, ++info) {
        if(info->kind != EucCSSLayoutDocumentRunComponentKindHyphenationRule 
           || i == startComponentOffset || i == lastComponentOffset) {
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
                currentDocumentNode = info->documentNode;
            }
            if(info->kind == EucCSSLayoutDocumentRunComponentKindHyphenationRule) {
                if(i == startComponentOffset) {
                    _componentWidth += info->widthAfterHyphen;
                }
            } else {
                _componentWidth += info->width;
            }
        }
    }
    
    // Stopping 'just before' a hyphen component really means that we stop
    // after the first part of the hyphenated word.
    if(i < documentRun.componentsCount) {
        if(info->kind == EucCSSLayoutDocumentRunComponentKindHyphenationRule) {
            _componentWidth -= info->width;
            _componentWidth += info->widthBeforeHyphen;
        }
    }
    
    
    _baseline = currentBaseline;
    _size = CGSizeMake(width, lineBoxHeight);
}

- (CGRect)frame
{
    return CGRectMake(_origin.x, _origin.y, _size.width, _size.height);
}

- (size_t)renderItemCount
{
    if(!_renderItems) {
        [self renderItems];
    }
    return _renderItemCount;
}

- (EucCSSLayoutLineRenderItem *)renderItems
{
    if(!_renderItems) {
        EucCSSLayoutDocumentRun *documentRun = self.containingRun.documentRun;
        
        size_t componentsCount = documentRun.componentsCount;
        uint32_t startComponentOffset = [documentRun pointToComponentOffset:_startPoint];
        uint32_t lastComponentOffset = [documentRun pointToComponentOffset:_endPoint] - 1;
        
        _renderItems = calloc(sizeof(EucCSSLayoutLineRenderItem), componentsCount);
        
        CGFloat xPosition = _origin.x;
        CGFloat yPosition = _origin.y;
        CGFloat baseline = _baseline;        
        
        CGFloat extraWidthNeeded = 0.0f;
        CGFloat spacesRemaining = 0.0f;
        
        EucCSSLayoutDocumentRunComponentInfo *componentInfos = &(documentRun.componentInfos[startComponentOffset]);
        
        uint32_t i;
        EucCSSLayoutDocumentRunComponentInfo *info;
        
        switch(_align) {
            case CSS_TEXT_ALIGN_CENTER:
                xPosition += (_size.width - _componentWidth) * 0.5f;
                break;
            case CSS_TEXT_ALIGN_RIGHT:
                xPosition += _size.width - _componentWidth - _indent;
                break;
            case CSS_TEXT_ALIGN_JUSTIFY:
                for(i = startComponentOffset, info = componentInfos;
                    i < componentsCount && i <= lastComponentOffset; 
                    ++i, ++info) {
                    if(info->kind == EucCSSLayoutDocumentRunComponentKindSpace) {
                        spacesRemaining++;
                    }
                }    
                extraWidthNeeded = _size.width - _indent - _componentWidth;
                // Fall through.
            default:
                xPosition += _indent;
        }

        EucCSSLayoutLineRenderItem *renderItem = _renderItems;
        for(i = startComponentOffset, info = componentInfos;
            i < componentsCount && i <= lastComponentOffset; 
            ++i, ++info) {
            
            if(info->kind == EucCSSLayoutDocumentRunComponentKindWord) {
                renderItem->item = [(NSString *)info->component retain];
                renderItem->rect = CGRectMake(xPosition, yPosition + baseline - info->ascender, info->width, _size.height);
                renderItem->pointSize = info->pointSize;
                renderItem->point = info->point;
                renderItem->stringRenderer = [info->documentNode.stringRenderer retain];
                ++renderItem;
                ++_renderItemCount;
                
                xPosition += info->width;
            } else if(info->kind == EucCSSLayoutDocumentRunComponentKindSpace) {
                if(extraWidthNeeded != 0.0f) {
                    CGFloat extraSpace = extraWidthNeeded / spacesRemaining;
                    xPosition += extraSpace;
                    extraWidthNeeded -= extraSpace;
                    --spacesRemaining;
                }
                xPosition += info->width;
            } else if(info->kind == EucCSSLayoutDocumentRunComponentKindImage) {
                renderItem->item = [(UIImage *)info->component retain];
                renderItem->rect = CGRectMake(xPosition, yPosition + baseline - info->ascender, info->width, info->pointSize);
                renderItem->point = info->point;
                renderItem->altText = [[info->documentNode altText] retain];
                ++renderItem;
                ++_renderItemCount;
                
                xPosition += info->width;
            }
            if(info->kind == EucCSSLayoutDocumentRunComponentKindHyphenationRule) {
                if (i == startComponentOffset) {
                    renderItem->item = [(NSString *)info->component2 retain];
                    renderItem->rect = CGRectMake(xPosition, yPosition + baseline - info->ascender, info->widthAfterHyphen, _size.height);
                    renderItem->pointSize = info->pointSize;
                    renderItem->point = info->point;
                    renderItem->stringRenderer = [info->documentNode.stringRenderer retain];
                    ++renderItem;
                    ++_renderItemCount;
                    
                    xPosition += info->widthAfterHyphen;
                }
            }
        }
        
        // Stopping 'just before' a hyphen component really means that we stop
        // after the first part of the hyphenated word.
        if(i < documentRun.componentsCount) {
            if(info->kind == EucCSSLayoutDocumentRunComponentKindHyphenationRule) {
                --renderItem;
                
                xPosition -= info->width;
                
                // Store the entire word in the alt text for accessibility.
                renderItem->altText = renderItem->item;
                
                renderItem->item = [(NSString *)info->component retain];
                renderItem->rect = CGRectMake(xPosition, yPosition + baseline - info->ascender, info->widthBeforeHyphen, _size.height);
                renderItem->point = info->point;
                ++renderItem;                
            }
        }
    }
    return _renderItems;
}

- (NSComparisonResult)compare:(EucCSSLayoutLine *)rhs 
{
    return self < rhs ? NSOrderedAscending : (self > rhs ? NSOrderedDescending : NSOrderedSame);
}

@end
