//
//  EucCSSLayoutPositionedLine.m
//  LibCSSTest
//
//  Created by James Montgomerie on 12/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif

#import "EucCSSInternal.h"
#import "EucCSSLayoutPositionedLine.h"
#import "EucCSSIntermediateDocumentNode.h"
#import "EucCSSLayoutPositionedRun.h"
#import "EucCSSLayoutDocumentRun.h"
#import "EucCSSLayoutDocumentRun_Package.h"
#import "THLog.h"

#import <libcss/libcss.h>

@implementation EucCSSLayoutPositionedLine

@synthesize startPoint = _startPoint;
@synthesize endPoint = _endPoint;

@synthesize componentWidth = _componentWidth;

@synthesize indent = _indent;
@synthesize baseline = _baseline;

@synthesize align = _align;

- (void)dealloc
{    
    EucCSSLayoutPositionedLineRenderItem *renderItem = _renderItems;
    EucCSSLayoutPositionedLineRenderItem *renderItemEnd = _renderItems + _renderItemCount;
    for(; renderItem < renderItemEnd; ++renderItem) {
        switch (renderItem->kind) {
            case EucCSSLayoutPositionedLineRenderItemKindString:
                [renderItem->item.stringItem.string release];
                break;
            case EucCSSLayoutPositionedLineRenderItemKindImage:
                CGImageRelease(renderItem->item.imageItem.image);
                break;
            default:
                break;
        }
        if(renderItem->altText) {
            [renderItem->altText release];
        }
    }
    free(_renderItems);
    
    [super dealloc];
}

static inline void halfLeadingAndCorrectedLineHeightForLineHeightAndEmHeight(CGFloat inlineBoxHeight, CGFloat emBoxHeight,
                                                                             CGFloat *halfLeading, CGFloat *correctedLineHeight) 
{
    CGFloat prepareBoxHeight = inlineBoxHeight;
    CGFloat prepareHalfLeading = (prepareBoxHeight - emBoxHeight) * 0.5f;
    CGFloat remainder = fmodf(prepareHalfLeading, 1.0f);
    if(remainder != 0.0f) {
        prepareHalfLeading += 1.0f - remainder;
        prepareBoxHeight += 1.0f;
    }
    *halfLeading = prepareHalfLeading;
    *correctedLineHeight = prepareBoxHeight;
}
                                    
static BOOL _adjustLineBoxToContainLineBox(EucCSSLayoutPositionedLineLineBox *containerLineBox, EucCSSLayoutPositionedLineLineBox *containedLineBox)
{
    BOOL changed = NO;
    switch(containedLineBox->verticalAlign) {
        default:
        {
            THWarn("Unexpected vertical-align: %ld", (long)containedLineBox->verticalAlign);
            // Fall through
        }
        case CSS_VERTICAL_ALIGN_BASELINE:
        {            
            CGFloat containerDescenderAndLineHeightAddition = containerLineBox->height - containerLineBox->baseline;
            CGFloat containedDescenderAndLineHeightAddition = containedLineBox->height - containedLineBox->baseline;
            if(containedLineBox->baseline > containerLineBox->baseline) {
                containerLineBox->baseline = containedLineBox->baseline;
                changed = YES;
            }
            CGFloat newHeight = containerLineBox->baseline + MAX(containerDescenderAndLineHeightAddition, containedDescenderAndLineHeightAddition);
            if(newHeight != containerLineBox->height) {
                containerLineBox->height = newHeight;
                changed = YES;
            }
            break;
        }                                   
        case CSS_VERTICAL_ALIGN_SUB:
        case CSS_VERTICAL_ALIGN_SUPER:
        case CSS_VERTICAL_ALIGN_SET:
        {
            CGFloat adjustedBaseline = containedLineBox->baseline - containedLineBox->verticalAlignSetOffset;
            
            CGFloat containerDescenderAndLineHeightAddition = containerLineBox->height - containerLineBox->baseline;
            CGFloat containedDescenderAndLineHeightAddition = containedLineBox->height - containedLineBox->baseline + containedLineBox->verticalAlignSetOffset;            
            
            if(adjustedBaseline > containerLineBox->baseline) {
                containerLineBox->baseline = adjustedBaseline;
                changed = YES;
            }
            CGFloat newHeight = containerLineBox->baseline + MAX(containerDescenderAndLineHeightAddition, containedDescenderAndLineHeightAddition);
            if(newHeight != containerLineBox->height) {
                containerLineBox->height = newHeight;
                changed = YES;
            }
            break;
        }
        /*case CSS_VERTICAL_ALIGN_TEXT_TOP:
        case CSS_VERTICAL_ALIGN_MIDDLE:
        case CSS_VERTICAL_ALIGN_TEXT_BOTTOM:
        case CSS_VERTICAL_ALIGN_TOP:
        case CSS_VERTICAL_ALIGN_BOTTOM:
            break;*/
    }
    
    containerLineBox->width += containedLineBox->width;
    
    return changed;
}

static inline void _placeRenderItemInRenderItem(EucCSSLayoutPositionedLineRenderItem *child, EucCSSLayoutPositionedLineRenderItem *parent)
{
    enum css_vertical_align_e verticalAlign = child->lineBox.verticalAlign;
    switch(verticalAlign) {
        default:
        {
            THWarn("Unexpected vertical-align: %ld", (long)verticalAlign);
            // Fall through
        }
        case CSS_VERTICAL_ALIGN_BASELINE:
        {            
            child->origin.y = parent->lineBox.baseline - child->lineBox.baseline;
            break;
        }   
        case CSS_VERTICAL_ALIGN_SUB:
        case CSS_VERTICAL_ALIGN_SUPER:
        case CSS_VERTICAL_ALIGN_SET:
        {
            child->origin.y = parent->lineBox.baseline - child->lineBox.baseline;
            child->origin.y += child->lineBox.verticalAlignSetOffset;
            break;            
        }
    }    
}


static EucCSSLayoutPositionedLineLineBox lineBoxForDocumentNode(EucCSSIntermediateDocumentNode *node, CGFloat scaleFactor)
{
    EucCSSLayoutPositionedLineLineBox myLineBox = { 0 };
        
    css_computed_style *style = node.computedStyle;
    if(style) {        
        css_fixed verticalAlignSize = verticalAlignSize;
        css_unit verticalAlignSizeUnit = verticalAlignSizeUnit;
        NSUInteger verticalAlign = css_computed_vertical_align(style, &verticalAlignSize, &verticalAlignSizeUnit);
        myLineBox.verticalAlign = verticalAlign;
        if(verticalAlign == CSS_VERTICAL_ALIGN_SUPER) {
            myLineBox.verticalAlignSetOffset = -[node.parent xHeightAtScaleFactor:scaleFactor];
        } else if(verticalAlign == CSS_VERTICAL_ALIGN_SUB) {
            myLineBox.verticalAlignSetOffset = [node.parent xHeightAtScaleFactor:scaleFactor];
        } else if(verticalAlign == CSS_VERTICAL_ALIGN_SET) {
            myLineBox.verticalAlignSetOffset = EucCSSLibCSSSizeToPixels(style, verticalAlignSize, verticalAlignSizeUnit, [node lineHeightAtScaleFactor:scaleFactor], scaleFactor);
        }
    } else {
        myLineBox.verticalAlign = CSS_VERTICAL_ALIGN_BASELINE;
    }
    
    css_fixed verticalAlignSize = verticalAlignSize;
    css_unit verticalAlignSizeUnit = verticalAlignSizeUnit;
    
    
    CGFloat halfLeading = halfLeading;
    halfLeadingAndCorrectedLineHeightForLineHeightAndEmHeight([node lineHeightAtScaleFactor:scaleFactor], 
                                                              [node textPointSizeAtScaleFactor:scaleFactor],
                                                              &halfLeading, &myLineBox.height);
    myLineBox.baseline = [node textAscenderAtScaleFactor:scaleFactor] + halfLeading;
        
    return myLineBox;
}

static EucCSSLayoutPositionedLineLineBox lineBoxForComponentInfo(EucCSSLayoutDocumentRunComponentInfo *componentInfo, CGFloat scaleFactor)
{    
    if(componentInfo->kind == EucCSSLayoutDocumentRunComponentKindImage) {
        EucCSSLayoutPositionedLineLineBox imageLineBox = {
            componentInfo->contents.imageInfo.scaledSize.width,
            componentInfo->contents.imageInfo.scaledSize.height,
            componentInfo->contents.imageInfo.scaledSize.height,
            CSS_VERTICAL_ALIGN_BASELINE
        };
        return imageLineBox;
    } else {
        EucCSSLayoutPositionedLineLineBox componentLineBox = lineBoxForDocumentNode(componentInfo->documentNode, scaleFactor);
        componentLineBox.width = componentInfo->width;
        return componentLineBox;
    }
}

static EucCSSLayoutPositionedLineLineBox processNode(uint32_t *componentOffset, EucCSSLayoutDocumentRunComponentInfo **componentInfo, uint32_t afterEndComponentOffset, CGFloat scaleFactor) 
{
    
    uint32_t i = *componentOffset;
    EucCSSLayoutDocumentRunComponentInfo *info = *componentInfo;
    
    EucCSSLayoutPositionedLineLineBox myLineBox = lineBoxForComponentInfo(info, scaleFactor);
    ++i;
    ++info;
    
    while(info->kind != EucCSSLayoutDocumentRunComponentKindCloseNode && 
          i < afterEndComponentOffset) {
        if(info->kind == EucCSSLayoutDocumentRunComponentKindOpenNode) {
            EucCSSLayoutPositionedLineLineBox subNodeBox = processNode(&i, &info, afterEndComponentOffset, scaleFactor);
            NSCParameterAssert(i == afterEndComponentOffset || info->kind == EucCSSLayoutDocumentRunComponentKindCloseNode);
            _adjustLineBoxToContainLineBox(&myLineBox, &subNodeBox);
            if(i == afterEndComponentOffset) {
                break;
            }
        } else if(info->kind == EucCSSLayoutDocumentRunComponentKindImage) {
            EucCSSLayoutPositionedLineLineBox imageLineBox = lineBoxForComponentInfo(info, scaleFactor);
            _adjustLineBoxToContainLineBox(&myLineBox, &imageLineBox);
        } else {
            if(info->kind != EucCSSLayoutDocumentRunComponentKindHyphenationRule) {
                myLineBox.width += info->width;
            }
        }
        ++i, ++info;
    }
    
    /// TODO:  Subtract the width vs hypenated width difference for first node if it's a hyphenation rule at the end.
    
    *componentOffset = i;
    *componentInfo = info;
    
    return myLineBox;
}

- (void)sizeToFitInWidth:(CGFloat)width
{
    if(!_componentWidth) {
        EucCSSLayoutDocumentRun *documentRun = ((EucCSSLayoutPositionedRun *)self.parent).documentRun; 
        CGFloat scaleFactor = documentRun.scaleFactor;
                
        size_t componentsCount = documentRun.componentsCount;
        
        uint32_t componentOffset = [documentRun pointToComponentOffset:_startPoint];
        uint32_t afterEndComponentOffset = [documentRun pointToComponentOffset:_endPoint];
        EucCSSLayoutDocumentRunComponentInfo *startComponentInfo = &(documentRun.componentInfos[componentOffset]);
        EucCSSLayoutDocumentRunComponentInfo *componentInfo = startComponentInfo;
                        
        if(afterEndComponentOffset > componentsCount) {
            afterEndComponentOffset = componentsCount;
        }
                
        EucCSSLayoutPositionedLineLineBox lineBox = { 0 };
        
        while(componentOffset < afterEndComponentOffset) {
            // May not come in here if the line contains no components (e.g. 
            // it contains some floats but is in an otherwise an empty block 
            // node)
            
            while(componentOffset < afterEndComponentOffset && 
                  componentInfo->kind == EucCSSLayoutDocumentRunComponentKindFloat) {
                ++componentOffset;
                ++componentInfo;
            }
            if(componentOffset >= afterEndComponentOffset) {
                break;
            }
            
            if(componentInfo->kind == EucCSSLayoutDocumentRunComponentKindHyphenationRule) {
                lineBox.width = componentInfo->contents.hyphenationInfo.widthAfterHyphen - componentInfo->width;
            }            
            
            EucCSSLayoutPositionedLineLineBox subnodeLineBox = processNode(&componentOffset, &componentInfo, afterEndComponentOffset, scaleFactor);
            NSCParameterAssert(componentOffset == afterEndComponentOffset || 
                               componentInfo->kind == EucCSSLayoutDocumentRunComponentKindCloseNode);
            
            _adjustLineBoxToContainLineBox(&lineBox, &subnodeLineBox);
            
            if(componentOffset < afterEndComponentOffset) {
                ++componentOffset;
                ++componentInfo;
            }
        }

        // Stopping 'just before' a hyphen component really means that we stop
        // after the first part of the hyphenated word.
        if(componentOffset < componentsCount) {
            if(componentInfo->kind == EucCSSLayoutDocumentRunComponentKindHyphenationRule) {
                lineBox.width -= componentInfo->width;
                lineBox.width += componentInfo->contents.hyphenationInfo.widthBeforeHyphen;
            }
        }
        
        // Now take into acunt our parent nodes' affect on the line box.
        componentInfo = startComponentInfo;
        EucCSSIntermediateDocumentNode *node = componentInfo->documentNode.parent;
        css_computed_style *style;
        while(style = node.computedStyle,
              !style || css_computed_display(style, NO) != CSS_DISPLAY_BLOCK) {
            EucCSSLayoutPositionedLineLineBox parentNodeBox = lineBoxForDocumentNode(node, scaleFactor);
            _adjustLineBoxToContainLineBox(&lineBox, &parentNodeBox);
            node = node.parent;
        }
              
        _lineBox = lineBox;
        
        _componentWidth = lineBox.width;
        _baseline = lineBox.baseline;
        
        CGRect frame = self.frame;
        frame.size = CGSizeMake(width, lineBox.height);
        self.frame = frame;
    } else {
        CGRect frame = self.frame;
        frame.size.width = width;
        self.frame = frame;
    }
}

- (CGFloat)minimumWidth
{
    return ceilf(_componentWidth + _indent);
}

- (size_t)renderItemCount
{
    if(!_renderItems) {
        [self renderItems];
    }
    return _renderItemCount;
}

static inline void _incrementRenderitemsCount(EucCSSLayoutPositionedLineRenderItem **currentRenderItem, size_t *renderItemCount, size_t *renderItemCapacity, EucCSSLayoutPositionedLineRenderItem **renderItems) 
{
    ++*renderItemCount;
    if(*renderItemCount == *renderItemCapacity) { 
        size_t oldCapacity = *renderItemCapacity;
        *renderItemCapacity *= 2; 
        *renderItems = realloc(*renderItems, *renderItemCapacity * sizeof(EucCSSLayoutPositionedLineRenderItem)); 
        bzero((*renderItems) + oldCapacity, oldCapacity * sizeof(EucCSSLayoutPositionedLineRenderItem));
        *currentRenderItem = (*renderItems) + oldCapacity;
    } else {
        ++*currentRenderItem;
    }
}


static inline void _adjustParentsToContainRenderItem(EucCSSLayoutPositionedLineRenderItem *renderItems, size_t renderItemCount, NSUInteger childIndex) {
    NSUInteger parentIndex = renderItems[childIndex].parentIndex;
    if(parentIndex != NSUIntegerMax) {
        // Expand the size of the parent, if necessary.
        BOOL sizeChanged = _adjustLineBoxToContainLineBox(&renderItems[parentIndex].lineBox, &renderItems[childIndex].lineBox);
        
        // If the size or baseline of the parent changed.
        if(sizeChanged) {
            // (Re-)place all the children.
            for(NSUInteger i = parentIndex + 1; i < renderItemCount; ++i) {
                if(renderItems[i].parentIndex == parentIndex) {
                    _placeRenderItemInRenderItem(renderItems + i, renderItems + parentIndex);
                }
            }
            
            // Recurse, to make sure our parent is placed properly in our parent 
            // now it's changed size.
            _adjustParentsToContainRenderItem(renderItems, renderItemCount, renderItems[childIndex].parentIndex);
        } else {
            _placeRenderItemInRenderItem(renderItems + childIndex, renderItems + parentIndex);   
        }
    }
}

static inline void _accumulateParentLineBoxesInto(EucCSSIntermediateDocumentNode *node, CGFloat scaleFactor, EucCSSLayoutPositionedLineRenderItem **currentRenderItem, size_t *renderItemCount, size_t *renderItemCapacity, EucCSSLayoutPositionedLineRenderItem **renderItems)
{
    css_computed_style *style = node.computedStyle;
    BOOL doParent = (!style || css_computed_display(style, NO) != CSS_DISPLAY_BLOCK);
    if(doParent) {
        _accumulateParentLineBoxesInto(node.parent, scaleFactor, currentRenderItem, renderItemCount, renderItemCapacity, renderItems);
    }
    (*currentRenderItem)->kind = EucCSSLayoutPositionedLineRenderItemKindOpenNode;
    (*currentRenderItem)->parentIndex = doParent ? *currentRenderItem - *renderItems - 1 : NSUIntegerMax;
    (*currentRenderItem)->lineBox = lineBoxForDocumentNode(node, scaleFactor);
    (*currentRenderItem)->item.openNodeInfo.node = node;
    (*currentRenderItem)->item.openNodeInfo.implicit = YES;
    
    if(doParent) {
        _adjustParentsToContainRenderItem(*renderItems, *renderItemCount, *currentRenderItem - *renderItems);
    }
    _incrementRenderitemsCount(currentRenderItem, renderItemCount, renderItemCapacity, renderItems);
}

- (EucCSSLayoutPositionedLineRenderItem *)renderItems
{
    if(!_renderItems) {
        EucCSSLayoutDocumentRun *documentRun = ((EucCSSLayoutPositionedRun *)self.parent).documentRun;
        CGFloat scaleFactor = documentRun.scaleFactor;
        
        size_t componentsCount = documentRun.componentsCount;
        uint32_t startComponentOffset = [documentRun pointToComponentOffset:_startPoint];
        uint32_t afterEndComponentOffset = [documentRun pointToComponentOffset:_endPoint];
        
        _renderItems = calloc(sizeof(EucCSSLayoutPositionedLineRenderItem), componentsCount);
        size_t renderItemCapacity = componentsCount;
        EucCSSLayoutPositionedLineRenderItem *renderItem = _renderItems;

        CGRect contentBounds = self.contentBounds;
        CGSize size = contentBounds.size;
        CGFloat xPosition = contentBounds.origin.x;        
        
        CGFloat extraWidthNeeded = 0.0f;
        CGFloat spacesRemaining = 0.0f;
        
        EucCSSLayoutDocumentRunComponentInfo *componentInfos = &(documentRun.componentInfos[startComponentOffset]);
        
        
        switch(_align) {
            case CSS_TEXT_ALIGN_CENTER:
                xPosition += (size.width - _componentWidth) * 0.5f;
                break;
            case CSS_TEXT_ALIGN_RIGHT:
                xPosition += size.width - _componentWidth - _indent;
                break;
            case CSS_TEXT_ALIGN_JUSTIFY:
            {
                uint32_t i;
                EucCSSLayoutDocumentRunComponentInfo *info;
                for(i = startComponentOffset, info = componentInfos;
                    i < componentsCount && i < afterEndComponentOffset; 
                    ++i, ++info) {
                    if(info->kind == EucCSSLayoutDocumentRunComponentKindSpace || 
                       info->kind == EucCSSLayoutDocumentRunComponentKindNonbreakingSpace) {
                        spacesRemaining++;
                    }
                }    
                extraWidthNeeded = size.width - _indent - _componentWidth;
                // Fall through.
            }
            default:
                xPosition += _indent;
        }

        CGFloat pointSize = 0.0f;
        CGFloat ascender = 0.0f;
        CGFloat xHeight = 0.0f;
        
        BOOL doParents;
        
        EucCSSIntermediateDocumentNode *node = componentInfos[0].documentNode;
        if(componentInfos[0].kind == EucCSSLayoutDocumentRunComponentKindOpenNode) {
            css_computed_style *style = node.computedStyle;
            doParents = (!style || css_computed_display(style, NO) != CSS_DISPLAY_BLOCK);
            if(doParents) {
                node = node.parent;
            }
        } else {
            if(componentInfos[0].kind == EucCSSLayoutDocumentRunComponentKindFloat) {
                // We don't want the float's attributes!
                node = node.parent;
            }
            pointSize = [node textPointSizeAtScaleFactor:scaleFactor];
            ascender = [node textAscenderAtScaleFactor:scaleFactor];
            doParents = YES;           
        }
        
        if(doParents) {
            _accumulateParentLineBoxesInto(node, scaleFactor, &renderItem, &_renderItemCount, &renderItemCapacity, &_renderItems);
            _renderItems[0].origin.x = xPosition;
        }
        
        NSUInteger parentIndex = doParents ? _renderItemCount - 1 : NSUIntegerMax;
        
        CGFloat thisNodeAbsoluteX = xPosition;
        
        uint32_t i;
        EucCSSLayoutDocumentRunComponentInfo *info;
        for(i = startComponentOffset, info = componentInfos;
            i < componentsCount && i < afterEndComponentOffset; 
            ++i, ++info) {
            switch(info->kind) {
                case EucCSSLayoutDocumentRunComponentKindSpace:
                case EucCSSLayoutDocumentRunComponentKindNonbreakingSpace:
                {
                    if(extraWidthNeeded != 0.0f) {
                        CGFloat extraSpace = extraWidthNeeded / spacesRemaining;
                        xPosition += extraSpace;
                        extraWidthNeeded -= extraSpace;
                        --spacesRemaining;
                    }
                    xPosition += info->width;                  
                    break;   
                }
                case EucCSSLayoutDocumentRunComponentKindWord:
                {
                    renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindString;
                    renderItem->parentIndex = parentIndex;
                    renderItem->origin.x = xPosition - thisNodeAbsoluteX;
                    renderItem->origin.y = _renderItems[parentIndex].lineBox.baseline - ascender;
                    
                    renderItem->lineBox.width = info->width;
                    renderItem->lineBox.height = pointSize;
                    renderItem->lineBox.baseline = ascender;
                    renderItem->lineBox.verticalAlign = CSS_VERTICAL_ALIGN_BASELINE;
                    
                    renderItem->item.stringItem.string = [info->contents.stringInfo.string retain];
                    renderItem->item.stringItem.layoutPoint = info->point;

                    _placeRenderItemInRenderItem(renderItem, _renderItems + parentIndex);
                    
                    _incrementRenderitemsCount(&renderItem, &_renderItemCount, &renderItemCapacity, &_renderItems);
                    
                    xPosition += info->width;
                    break;
                }
                case EucCSSLayoutDocumentRunComponentKindHyphenationRule:
                {
                    if(i == startComponentOffset) {
                        renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindString;
                        renderItem->parentIndex = parentIndex;
                        renderItem->origin.x = xPosition - thisNodeAbsoluteX;
                        
                        renderItem->lineBox.width = info->contents.hyphenationInfo.widthAfterHyphen;
                        renderItem->lineBox.height = pointSize;
                        renderItem->lineBox.baseline = ascender;
                        renderItem->lineBox.verticalAlign = CSS_VERTICAL_ALIGN_BASELINE;
                        
                        renderItem->item.stringItem.string = [info->contents.hyphenationInfo.afterHyphen retain];
                        renderItem->item.stringItem.layoutPoint = info->point;
                                                
                        _placeRenderItemInRenderItem(renderItem, _renderItems + parentIndex);
                        
                        _incrementRenderitemsCount(&renderItem, &_renderItemCount, &renderItemCapacity, &_renderItems);
                        
                        xPosition += info->contents.hyphenationInfo.widthAfterHyphen;
                        break;                        
                    }
                    break;
                }
                case EucCSSLayoutDocumentRunComponentKindImage:
                {
                    renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindImage;
                    renderItem->parentIndex = parentIndex;
                    renderItem->origin.x = xPosition - thisNodeAbsoluteX;
                    
                    renderItem->lineBox.width = info->contents.imageInfo.scaledSize.width;
                    renderItem->lineBox.height = info->contents.imageInfo.scaledSize.height;
                    renderItem->lineBox.baseline = info->contents.imageInfo.scaledSize.height;
                    renderItem->lineBox.verticalAlign = CSS_VERTICAL_ALIGN_BASELINE;
                    
                    renderItem->item.imageItem.image = CGImageRetain(info->contents.imageInfo.image);
                    renderItem->item.imageItem.layoutPoint = info->point;

                    renderItem->altText = [[info->documentNode altText] retain];
                    
                    _incrementRenderitemsCount(&renderItem, &_renderItemCount, &renderItemCapacity, &_renderItems);

                    _adjustParentsToContainRenderItem(_renderItems, _renderItemCount, _renderItemCount - 1);

                    xPosition += info->width;                    
                    break;
                }
                case EucCSSLayoutDocumentRunComponentKindOpenNode:
                {
                    EucCSSIntermediateDocumentNode *node = info->documentNode;

                    renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindOpenNode;
                    renderItem->origin.x = xPosition - thisNodeAbsoluteX; // is already 0.
                    
                    thisNodeAbsoluteX += renderItem->origin.x;
                    
                    renderItem->parentIndex = parentIndex;
                    renderItem->lineBox = lineBoxForDocumentNode(node, scaleFactor);
                    renderItem->item.openNodeInfo.node = node;
                    
                    parentIndex = _renderItemCount;
                    
                    _incrementRenderitemsCount(&renderItem, &_renderItemCount, &renderItemCapacity, &_renderItems);
                    
                    _adjustParentsToContainRenderItem(_renderItems, _renderItemCount, _renderItemCount - 1);
                    
                    pointSize = [node textPointSizeAtScaleFactor:scaleFactor];
                    ascender = [node textAscenderAtScaleFactor:scaleFactor];
                    xHeight = [node xHeightAtScaleFactor:scaleFactor];
                    
                    xPosition += info->width;                    
                    break;
                }
                case EucCSSLayoutDocumentRunComponentKindCloseNode:
                {
                    EucCSSIntermediateDocumentNode *node = info->documentNode;

                    renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindCloseNode;
                    renderItem->origin.x = xPosition - thisNodeAbsoluteX;
                    renderItem->lineBox = _renderItems[parentIndex].lineBox;
                    renderItem->lineBox.width = info->width;
                    
                    renderItem->parentIndex = parentIndex;
                    renderItem->item.closeNodeInfo.node = node;

                    _renderItems[parentIndex].lineBox.width = xPosition - thisNodeAbsoluteX;
                    
                    _incrementRenderitemsCount(&renderItem, &_renderItemCount, &renderItemCapacity, &_renderItems);
                    
                    thisNodeAbsoluteX -= _renderItems[parentIndex].origin.x;
                    xPosition += info->width;                    
                    parentIndex = _renderItems[parentIndex].parentIndex;

                    pointSize = [node.parent textPointSizeAtScaleFactor:scaleFactor];
                    ascender = [node.parent textAscenderAtScaleFactor:scaleFactor];     
                    xHeight = [node.parent xHeightAtScaleFactor:scaleFactor];
                    
                    break;
                }
                case EucCSSLayoutDocumentRunComponentKindFloat:
                {
                    renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindFloatPlaceholder;
                    renderItem->parentIndex = parentIndex;
                    _incrementRenderitemsCount(&renderItem, &_renderItemCount, &renderItemCapacity, &_renderItems);
                    break;
                }
                default:
                {
                    THWarn(@"Unexpected component in line, kind %ld", (long)info->kind);
                }
            }
        }     
        
        // Stopping 'just before' a hyphen component really means that we stop
        // after the first part of the hyphenated word.
        if(i < componentsCount) {
            if(info->kind == EucCSSLayoutDocumentRunComponentKindHyphenationRule) {
                --renderItem;
                
                xPosition -= info->width;
                xPosition += info->contents.hyphenationInfo.widthBeforeHyphen;
                                
                renderItem->lineBox.width = info->contents.hyphenationInfo.widthBeforeHyphen;

                // Store the entire word in the alt text for accessibility.
                renderItem->altText = renderItem->item.stringItem.string;                        
                
                renderItem->item.stringItem.string = [info->contents.hyphenationInfo.beforeHyphen retain];
                renderItem->item.stringItem.layoutPoint = info->point;
                
                ++renderItem;
            }
        }        
        
        // Close up any open nodes.
        while(parentIndex != NSUIntegerMax) {
            renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindCloseNode;
            renderItem->origin.x = xPosition - thisNodeAbsoluteX;
            renderItem->lineBox = _renderItems[parentIndex].lineBox;
            renderItem->lineBox.width = 0;
            
            renderItem->parentIndex = parentIndex;
            renderItem->item.closeNodeInfo.node = _renderItems[parentIndex].item.openNodeInfo.node;
            renderItem->item.closeNodeInfo.implicit = YES;

            _renderItems[parentIndex].lineBox.width = xPosition - thisNodeAbsoluteX;
            
            _incrementRenderitemsCount(&renderItem, &_renderItemCount, &renderItemCapacity, &_renderItems);

            thisNodeAbsoluteX -= _renderItems[parentIndex].origin.x;
            parentIndex = _renderItems[parentIndex].parentIndex;
        }
    }
    return _renderItems;
}

- (NSComparisonResult)compare:(EucCSSLayoutPositionedLine *)rhs 
{
    return self < rhs ? NSOrderedAscending : (self > rhs ? NSOrderedDescending : NSOrderedSame);
}

@end
