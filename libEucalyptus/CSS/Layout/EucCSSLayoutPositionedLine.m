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
#import "EucCSSIntermediateDocument.h"
#import "EucCSSIntermediateDocumentNode.h"
#import "EucCSSLayoutPositionedRun.h"
#import "EucCSSLayoutRun.h"
#import "EucCSSLayoutRun_Package.h"
#import "EucCSSLayoutSizedRun.h"
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
    
    return changed;
}

static BOOL _adjustLineBoxToContainLineBoxIncludingWidth(EucCSSLayoutPositionedLineLineBox *containerLineBox, EucCSSLayoutPositionedLineLineBox *containedLineBox)
{
    containerLineBox->width += containedLineBox->width;
    return _adjustLineBoxToContainLineBox(containerLineBox, containedLineBox);;
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
        css_fixed verticalAlignSize = 0;
        css_unit verticalAlignSizeUnit = (css_unit)0;
        NSUInteger verticalAlign = css_computed_vertical_align(style, &verticalAlignSize, &verticalAlignSizeUnit);
        myLineBox.verticalAlign = verticalAlign;
        if(verticalAlign == CSS_VERTICAL_ALIGN_SUPER) {
            myLineBox.verticalAlignSetOffset = -[node.parent xHeightWithScaleFactor:scaleFactor];
        } else if(verticalAlign == CSS_VERTICAL_ALIGN_SUB) {
            myLineBox.verticalAlignSetOffset = [node.parent xHeightWithScaleFactor:scaleFactor];
        } else if(verticalAlign == CSS_VERTICAL_ALIGN_SET) {
            myLineBox.verticalAlignSetOffset = EucCSSLibCSSSizeToPixels(style, verticalAlignSize, verticalAlignSizeUnit, [node lineHeightWithScaleFactor:scaleFactor], scaleFactor);
        }
    } else {
        myLineBox.verticalAlign = CSS_VERTICAL_ALIGN_BASELINE;
    }
        
    CGFloat halfLeading;
    halfLeadingAndCorrectedLineHeightForLineHeightAndEmHeight([node lineHeightWithScaleFactor:scaleFactor], 
                                                              [node textPointSizeWithScaleFactor:scaleFactor],
                                                              &halfLeading, &myLineBox.height);
    myLineBox.baseline = [node textAscenderWithScaleFactor:scaleFactor] + halfLeading;
        
    return myLineBox;
}

static EucCSSLayoutPositionedLineLineBox lineBoxForComponentInfo(EucCSSLayoutRunComponentInfo *componentInfo, EucCSSLayoutSizedRunWidthInfo *widthInfo, CGFloat scaleFactor)
{    
    if(componentInfo->kind == EucCSSLayoutRunComponentKindImage) {
        EucCSSLayoutPositionedLineLineBox imageLineBox = {
            0,
            widthInfo->size.height,
            widthInfo->size.height,
            CSS_VERTICAL_ALIGN_BASELINE,
            0
        };
        return imageLineBox;
    } else {
        return lineBoxForDocumentNode(componentInfo->documentNode, scaleFactor);
    }
}

static EucCSSLayoutPositionedLineLineBox processNode(uint32_t *componentOffset, EucCSSLayoutRunComponentInfo **pComponentInfo, EucCSSLayoutSizedRunWidthInfo **pWidthInfo, uint32_t afterEndComponentOffset, CGFloat scaleFactor) 
{
    
    uint32_t i = *componentOffset;
    EucCSSLayoutRunComponentInfo *componentInfo = *pComponentInfo;
    EucCSSLayoutSizedRunWidthInfo *widthInfo = *pWidthInfo;
    
    EucCSSLayoutPositionedLineLineBox myLineBox = lineBoxForComponentInfo(componentInfo, widthInfo, scaleFactor);
    ++i;
    ++componentInfo;
    ++widthInfo;
    
    while(componentInfo->kind != EucCSSLayoutRunComponentKindCloseNode && 
          i < afterEndComponentOffset) {
        if(componentInfo->kind == EucCSSLayoutRunComponentKindOpenNode) {
            EucCSSLayoutPositionedLineLineBox subNodeBox = processNode(&i, &componentInfo, &widthInfo, afterEndComponentOffset, scaleFactor);
            NSCParameterAssert(i == afterEndComponentOffset || componentInfo->kind == EucCSSLayoutRunComponentKindCloseNode);
            _adjustLineBoxToContainLineBox(&myLineBox, &subNodeBox);
            if(i == afterEndComponentOffset) {
                break;
            }
        } else if(componentInfo->kind == EucCSSLayoutRunComponentKindImage) {
            EucCSSLayoutPositionedLineLineBox imageLineBox = lineBoxForComponentInfo(componentInfo, widthInfo, scaleFactor);
            _adjustLineBoxToContainLineBox(&myLineBox, &imageLineBox);
        } else {
            if(componentInfo->kind != EucCSSLayoutRunComponentKindHyphenationRule) {
            }
        }
        ++i, ++componentInfo, ++widthInfo;
    }
    
    *componentOffset = i;
    *pComponentInfo = componentInfo;
    *pWidthInfo = widthInfo;
    
    return myLineBox;
}

- (void)sizeToFitInWidth:(CGFloat)width parentFrame:(CGRect)parentFrame
{
    EucCSSLayoutSizedRun *sizedRun = ((EucCSSLayoutPositionedRun *)self.parent).sizedRun; 
    EucCSSLayoutRun *run = sizedRun.run; 
    CGFloat scaleFactor = sizedRun.scaleFactor;
            
    size_t componentsCount = run.componentsCount;
    
    uint32_t componentOffset = [run pointToComponentOffset:_startPoint];
    uint32_t afterEndComponentOffset = [run pointToComponentOffset:_endPoint];
    EucCSSLayoutRunComponentInfo *startComponentInfo = run.componentInfos + componentOffset;
    EucCSSLayoutRunComponentInfo *componentInfo = startComponentInfo;
    EucCSSLayoutSizedRunWidthInfo *widthInfo = [sizedRun componentWidthInfosForFrame:parentFrame] + componentOffset;
                    
    if(afterEndComponentOffset > componentsCount) {
        afterEndComponentOffset = componentsCount;
    }
            
    EucCSSLayoutPositionedLineLineBox lineBox = { 0 };
    lineBox.verticalAlign = CSS_VERTICAL_ALIGN_BASELINE;
    
    while(componentOffset < afterEndComponentOffset) {
        while(componentOffset < afterEndComponentOffset && 
              componentInfo->kind == EucCSSLayoutRunComponentKindFloat) {
            ++componentOffset;
            ++componentInfo;
            ++widthInfo;
        }
        if(componentOffset >= afterEndComponentOffset) {
            break;
        }
                    
        EucCSSLayoutPositionedLineLineBox subnodeLineBox = processNode(&componentOffset, &componentInfo, &widthInfo, afterEndComponentOffset, scaleFactor);
        NSCParameterAssert(componentOffset == afterEndComponentOffset || 
                           componentInfo->kind == EucCSSLayoutRunComponentKindCloseNode);
        
        _adjustLineBoxToContainLineBox(&lineBox, &subnodeLineBox);
        
        if(componentOffset < afterEndComponentOffset) {
            ++componentOffset;
            ++componentInfo;
            ++widthInfo;
        }
    }
    
    // Now take into account our parent nodes' affect on the line box.
    componentInfo = startComponentInfo;
    EucCSSIntermediateDocumentNode *node = componentInfo->documentNode.parent;
    while(node.display != CSS_DISPLAY_BLOCK) {
        if(node.computedStyle) {
            EucCSSLayoutPositionedLineLineBox parentNodeBox = lineBoxForDocumentNode(node, scaleFactor);
            _adjustLineBoxToContainLineBox(&parentNodeBox, &lineBox);
            node = node.parent;
            lineBox = parentNodeBox;
        }
    }

    CGRect frame = self.frame;
    frame.size = CGSizeMake(width, lineBox.height);
    self.frame = frame;
    
    _parentFrame = parentFrame;
}


- (void)sizeToFitInWidth:(CGFloat)width
{
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
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
        BOOL sizeChanged = _adjustLineBoxToContainLineBoxIncludingWidth(&renderItems[parentIndex].lineBox, &renderItems[childIndex].lineBox);
        
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
    BOOL doParent = node.display != CSS_DISPLAY_BLOCK;
    if(doParent) {
        EucCSSIntermediateDocumentNode *parent = node.parent;
        if(!parent.computedStyle) {
            // An inline text node, skip it.
            parent = parent.parent;
        }
        _accumulateParentLineBoxesInto(parent, scaleFactor, currentRenderItem, renderItemCount, renderItemCapacity, renderItems);
    }
    (*currentRenderItem)->kind = EucCSSLayoutPositionedLineRenderItemKindOpenNode;
    (*currentRenderItem)->parentIndex = doParent ? *currentRenderItem - *renderItems - 1 : NSUIntegerMax;
    (*currentRenderItem)->lineBox = lineBoxForDocumentNode(node, scaleFactor);
    (*currentRenderItem)->item.openNodeInfo.node = node;
    (*currentRenderItem)->item.openNodeInfo.implicit = YES;
    
    _incrementRenderitemsCount(currentRenderItem, renderItemCount, renderItemCapacity, renderItems);

    if(doParent) {
        _adjustParentsToContainRenderItem(*renderItems, *renderItemCount, *currentRenderItem - *renderItems - 1);
    }
}

- (EucCSSLayoutPositionedLineRenderItem *)renderItems
{
    if(!_renderItems) {
        EucCSSLayoutSizedRun *sizedRun = ((EucCSSLayoutPositionedRun *)self.parent).sizedRun; 
        EucCSSLayoutRun *run = sizedRun.run; 
        CGFloat scaleFactor = sizedRun.scaleFactor;
        
        size_t componentsCount = run.componentsCount;
        uint32_t startComponentOffset = [run pointToComponentOffset:_startPoint];
        uint32_t afterEndComponentOffset = [run pointToComponentOffset:_endPoint];
        
        _renderItems = calloc(sizeof(EucCSSLayoutPositionedLineRenderItem), componentsCount);
        size_t renderItemCapacity = componentsCount;
        EucCSSLayoutPositionedLineRenderItem *renderItem = _renderItems;

        CGRect contentBounds = self.contentBounds;
        CGSize size = contentBounds.size;
        CGFloat xPosition = contentBounds.origin.x;        
        
        CGFloat extraWidthNeeded = 0.0f;
        CGFloat spacesRemaining = 0.0f;
        
        EucCSSLayoutRunComponentInfo *componentInfos = run.componentInfos + startComponentOffset;
        EucCSSLayoutSizedRunWidthInfo *widthInfos = [sizedRun componentWidthInfosForFrame:_parentFrame] + startComponentOffset;
        
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
                EucCSSLayoutRunComponentInfo *info;
                for(i = startComponentOffset, info = componentInfos;
                    i < componentsCount && i < afterEndComponentOffset; 
                    ++i, ++info) {
                    if(info->kind == EucCSSLayoutRunComponentKindSpace || 
                       info->kind == EucCSSLayoutRunComponentKindNonbreakingSpace) {
                        spacesRemaining++;
                    }
                }    
                extraWidthNeeded = size.width - _indent - _componentWidth;
                // Fall through.
            }
            default:
                xPosition += _indent;
        }

        EucCSSIntermediateDocumentNode *parentNode;
        if(componentInfos[0].kind == EucCSSLayoutRunComponentKindCloseNode) {
            parentNode = componentInfos[0].documentNode;
        } else {
            parentNode = componentInfos[0].documentNode.parent;
        }
        _accumulateParentLineBoxesInto(parentNode, scaleFactor, &renderItem, &_renderItemCount, &renderItemCapacity, &_renderItems);
        
        CGFloat pointSize = [parentNode textPointSizeWithScaleFactor:scaleFactor];
        CGFloat ascender = [parentNode textAscenderWithScaleFactor:scaleFactor];        
        
        NSUInteger parentIndex = _renderItemCount - 1;
        
        _renderItems[0].origin.x = xPosition;
        CGFloat thisNodeAbsoluteX = xPosition;
        
        uint32_t i;
        EucCSSLayoutRunComponentInfo *info;
        EucCSSLayoutSizedRunWidthInfo *widthInfo;
        for(i = startComponentOffset, info = componentInfos, widthInfo = widthInfos;
            i < componentsCount && i < afterEndComponentOffset; 
            ++i, ++info, ++widthInfo) {
            switch(info->kind) {
                case EucCSSLayoutRunComponentKindSpace:
                case EucCSSLayoutRunComponentKindNonbreakingSpace:
                {
                    if(extraWidthNeeded != 0.0f) {
                        CGFloat extraSpace = extraWidthNeeded / spacesRemaining;
                        xPosition += extraSpace;
                        extraWidthNeeded -= extraSpace;
                        --spacesRemaining;
                    }
                    xPosition += widthInfo->width;                  
                    break;   
                }
                case EucCSSLayoutRunComponentKindWord:
                {
                    renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindString;
                    renderItem->parentIndex = parentIndex;
                    renderItem->origin.x = xPosition - thisNodeAbsoluteX;
                    
                    renderItem->lineBox.width = widthInfo->width;
                    renderItem->lineBox.height = pointSize;
                    renderItem->lineBox.baseline = ascender;
                    renderItem->lineBox.verticalAlign = CSS_VERTICAL_ALIGN_BASELINE;
                    
                    renderItem->item.stringItem.string = [info->contents.stringInfo.string retain];
                    renderItem->item.stringItem.layoutPoint = info->point;

                    _placeRenderItemInRenderItem(renderItem, _renderItems + parentIndex);
                    
                    _incrementRenderitemsCount(&renderItem, &_renderItemCount, &renderItemCapacity, &_renderItems);
                    
                    xPosition += widthInfo->width;
                    break;
                }
                case EucCSSLayoutRunComponentKindHyphenationRule:
                {
                    if(i == startComponentOffset) {
                        renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindString;
                        renderItem->parentIndex = parentIndex;
                        renderItem->origin.x = xPosition - thisNodeAbsoluteX;

                        renderItem->lineBox.width = widthInfo->hyphenWidths.widthAfterHyphen;
                        renderItem->lineBox.height = pointSize;
                        renderItem->lineBox.baseline = ascender;
                        renderItem->lineBox.verticalAlign = CSS_VERTICAL_ALIGN_BASELINE;
                        
                        renderItem->item.stringItem.string = [info->contents.hyphenationInfo.afterHyphen retain];
                        renderItem->item.stringItem.layoutPoint = info->point;
                                                
                        _placeRenderItemInRenderItem(renderItem, _renderItems + parentIndex);
                        
                        _incrementRenderitemsCount(&renderItem, &_renderItemCount, &renderItemCapacity, &_renderItems);
                        
                        xPosition += widthInfo->hyphenWidths.widthAfterHyphen;
                        break;                        
                    }
                    break;
                }
                case EucCSSLayoutRunComponentKindImage:
                {
                    renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindImage;
                    renderItem->parentIndex = parentIndex;
                    renderItem->origin.x = xPosition - thisNodeAbsoluteX;
                    
                    renderItem->lineBox.width = widthInfo->size.width;
                    renderItem->lineBox.height = widthInfo->size.height;
                    renderItem->lineBox.baseline = widthInfo->size.height;
                    renderItem->lineBox.verticalAlign = CSS_VERTICAL_ALIGN_BASELINE;
                    
                    renderItem->item.imageItem.image = CGImageRetain([info->documentNode.document imageForURL:info->contents.imageInfo.imageURL]);
                    renderItem->item.imageItem.layoutPoint = info->point;

                    renderItem->altText = [[info->documentNode altText] retain];
                    
                    _incrementRenderitemsCount(&renderItem, &_renderItemCount, &renderItemCapacity, &_renderItems);

                    _adjustParentsToContainRenderItem(_renderItems, _renderItemCount, _renderItemCount - 1);

                    xPosition += widthInfo->size.width;                    
                    break;
                }
                case EucCSSLayoutRunComponentKindOpenNode:
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
                    
                    pointSize = [node textPointSizeWithScaleFactor:scaleFactor];
                    ascender = [node textAscenderWithScaleFactor:scaleFactor];
                    
                    xPosition += widthInfo->width;                    
                    break;
                }
                case EucCSSLayoutRunComponentKindCloseNode:
                {
                    EucCSSIntermediateDocumentNode *node = info->documentNode;

                    renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindCloseNode;
                    renderItem->origin.x = xPosition - thisNodeAbsoluteX;
                    renderItem->lineBox = _renderItems[parentIndex].lineBox;
                    renderItem->lineBox.width = widthInfo->width;
                    
                    renderItem->parentIndex = parentIndex;
                    renderItem->item.closeNodeInfo.node = node;

                    _renderItems[parentIndex].lineBox.width = xPosition - thisNodeAbsoluteX;
                    
                    _incrementRenderitemsCount(&renderItem, &_renderItemCount, &renderItemCapacity, &_renderItems);
                    
                    thisNodeAbsoluteX -= _renderItems[parentIndex].origin.x;
                    xPosition += widthInfo->width;                    
                    parentIndex = _renderItems[parentIndex].parentIndex;

                    pointSize = [node.parent textPointSizeWithScaleFactor:scaleFactor];
                    ascender = [node.parent textAscenderWithScaleFactor:scaleFactor];     
                    
                    break;
                }
                case EucCSSLayoutRunComponentKindFloat:
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
            if(info->kind == EucCSSLayoutRunComponentKindHyphenationRule) {
                --renderItem;
                
                xPosition -= widthInfo->width;
                xPosition += widthInfo->hyphenWidths.widthBeforeHyphen;
                                
                renderItem->lineBox.width = widthInfo->hyphenWidths.widthBeforeHyphen;

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
