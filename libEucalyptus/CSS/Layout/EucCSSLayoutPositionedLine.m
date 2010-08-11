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
                [renderItem->item.stringItem.stringRenderer release];
                break;
            case EucCSSLayoutPositionedLineRenderItemKindImage:
                CFRelease(renderItem->item.imageItem.image);
                break;
            case EucCSSLayoutPositionedLineRenderItemKindUnderlineStart:
            case EucCSSLayoutPositionedLineRenderItemKindUnderlineStop:
                break;
            case EucCSSLayoutPositionedLineRenderItemKindHyperlinkStart:
            case EucCSSLayoutPositionedLineRenderItemKindHyperlinkStop:
                [renderItem->item.hyperlinkItem.url release];
                break;
        }
        if(renderItem->altText) {
            [renderItem->altText release];
        }

    }
    free(_renderItems);
    
    [super dealloc];
}

- (void)sizeToFitInWidth:(CGFloat)width;
{
    EucCSSLayoutDocumentRun *documentRun = ((EucCSSLayoutPositionedRun *)self.parent).documentRun;
    CGFloat lineBoxHeight = 0;
    CGFloat currentBaseline = 0;
    
    size_t componentsCount = documentRun.componentsCount;
    
    uint32_t startComponentOffset = [documentRun pointToComponentOffset:_startPoint];
    uint32_t afterEndComponentOffset = [documentRun pointToComponentOffset:_endPoint];
    EucCSSLayoutDocumentRunComponentInfo *componentInfos = &(documentRun.componentInfos[startComponentOffset]);

    if(afterEndComponentOffset == startComponentOffset) {
        // This is a line with no components, ending in a hard break.
        // Set up to use the hard break itsself as the only component, so that
        // we pick up the line height.
        // This is a bit of a hack.
        afterEndComponentOffset = startComponentOffset + 1;
    }
    
    EucCSSIntermediateDocumentNode *currentDocumentNode = nil;
    uint32_t i;
    EucCSSLayoutDocumentRunComponentInfo *info;
    for(i = startComponentOffset, info = componentInfos;
        i < componentsCount && i < afterEndComponentOffset; 
        ++i, ++info) {
        if(info->kind != EucCSSLayoutDocumentRunComponentKindHyphenationRule 
           || i == startComponentOffset || i == afterEndComponentOffset - 1) {
            if(info->documentNode != currentDocumentNode) {
                CGFloat emBoxHeight = info->pointSize;
                CGFloat inlineBoxHeight = info->lineHeight;
                
                CGFloat halfLeading = (inlineBoxHeight - emBoxHeight) * 0.5f;
                
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
    
    CGRect frame = self.frame;
    frame.size = CGSizeMake(width, lineBoxHeight);
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

- (EucCSSLayoutPositionedLineRenderItem *)renderItems
{
    if(!_renderItems) {
        EucCSSLayoutDocumentRun *documentRun = ((EucCSSLayoutPositionedRun *)self.parent).documentRun;
        
        size_t componentsCount = documentRun.componentsCount;
        uint32_t startComponentOffset = [documentRun pointToComponentOffset:_startPoint];
        uint32_t afterEndComponentOffset = [documentRun pointToComponentOffset:_endPoint];
        
        _renderItems = calloc(sizeof(EucCSSLayoutPositionedLineRenderItem), componentsCount);
        
        CGRect contentBounds = self.contentBounds;
        CGSize size = contentBounds.size;
        CGFloat xPosition = contentBounds.origin.x;
        CGFloat yPosition = contentBounds.origin.y;
        CGFloat baseline = _baseline;        
        
        CGFloat extraWidthNeeded = 0.0f;
        CGFloat spacesRemaining = 0.0f;
        
        EucCSSLayoutDocumentRunComponentInfo *componentInfos = &(documentRun.componentInfos[startComponentOffset]);
        
        uint32_t i;
        EucCSSLayoutDocumentRunComponentInfo *info;
        
        switch(_align) {
            case CSS_TEXT_ALIGN_CENTER:
                xPosition += (size.width - _componentWidth) * 0.5f;
                break;
            case CSS_TEXT_ALIGN_RIGHT:
                xPosition += size.width - _componentWidth - _indent;
                break;
            case CSS_TEXT_ALIGN_JUSTIFY:
                for(i = startComponentOffset, info = componentInfos;
                    i < componentsCount && i < afterEndComponentOffset; 
                    ++i, ++info) {
                    if(info->kind == EucCSSLayoutDocumentRunComponentKindSpace) {
                        spacesRemaining++;
                    }
                }    
                extraWidthNeeded = size.width - _indent - _componentWidth;
                // Fall through.
            default:
                xPosition += _indent;
        }

        BOOL currentUnderline = NO;
        BOOL checkForUnderline = YES;
        
        NSURL *currentHyperlink = nil;
        BOOL checkForHyperlink = YES;
        
        EucCSSLayoutPositionedLineRenderItem *renderItem = _renderItems;
        for(i = startComponentOffset, info = componentInfos;
            i < componentsCount && i < afterEndComponentOffset; 
            ++i, ++info) {
            
            if(checkForUnderline) {
                css_computed_style *style = [info->documentNode computedStyle];
                if(!style) {
                    style = [(info->documentNode).parent computedStyle];
                }
                uint8_t decoration = css_computed_text_decoration(style);
                BOOL shouldUnderline = (decoration == CSS_TEXT_DECORATION_UNDERLINE);
                if(currentUnderline != shouldUnderline) {
                    renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindUnderlineStart;
                    renderItem->item.underlineItem.underlinePoint = CGPointMake(xPosition, yPosition + baseline + ceilf((info->lineHeight - info->pointSize) * 0.5f) + 0.5);
                    ++renderItem;
                    ++_renderItemCount;

                    currentUnderline = shouldUnderline;
                }
            }
            
            if(checkForHyperlink) {
                NSURL *href = nil;
                EucCSSIntermediateDocumentNode *documentNode = info->documentNode;
                while(!href && documentNode) {
                    if(documentNode.isHyperlinkNode) {
                        href = documentNode.hyperlinkURL;
                    }
                    documentNode = documentNode.parent;
                }
                if(href) {
                    if(currentHyperlink) {
                        if(![currentHyperlink isEqual:href]) {
                            renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindHyperlinkStop;
                            renderItem->item.hyperlinkItem.url = [currentHyperlink retain];
                            ++renderItem;
                            ++_renderItemCount;
                            [currentHyperlink release];
                            currentHyperlink = [href retain];
                            renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindHyperlinkStart;
                            renderItem->item.hyperlinkItem.url = [currentHyperlink retain];
                            ++renderItem;
                            ++_renderItemCount;
                        }
                    } else {
                        currentHyperlink = [href retain];
                        renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindHyperlinkStart;
                        renderItem->item.hyperlinkItem.url = [currentHyperlink retain];
                        ++renderItem;
                        ++_renderItemCount;                        
                    }
                } else {
                    if(currentHyperlink) {
                        renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindHyperlinkStop;
                        renderItem->item.hyperlinkItem.url = [currentHyperlink retain];
                        ++renderItem;
                        ++_renderItemCount;
                        [currentHyperlink release];
                        currentHyperlink = nil;
                    }
                }
                checkForHyperlink = NO;
            }
            
            if(info->kind == EucCSSLayoutDocumentRunComponentKindWord) {
                CGFloat emBoxHeight = info->pointSize;
                CGFloat inlineBoxHeight = info->lineHeight;
                CGFloat halfLeading = (inlineBoxHeight - emBoxHeight) * 0.5f;
                
                renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindString;
                renderItem->item.stringItem.string = [(NSString *)info->component retain];
                renderItem->item.stringItem.rect = CGRectMake(xPosition, yPosition + baseline - info->ascender - halfLeading, info->width, size.height);
                renderItem->item.stringItem.pointSize = info->pointSize;
                renderItem->item.stringItem.stringRenderer = [info->documentNode.stringRenderer retain];
                renderItem->item.stringItem.layoutPoint = info->point;
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
                renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindImage;
                renderItem->item.imageItem.image = CGImageRetain((CGImageRef)info->component);
                renderItem->item.imageItem.rect = CGRectMake(xPosition, yPosition + baseline - info->ascender, info->width, info->pointSize);
                renderItem->item.imageItem.layoutPoint = info->point;
                renderItem->altText = [[info->documentNode altText] retain];
                ++renderItem;
                ++_renderItemCount;
                
                xPosition += info->width;
            } else if(info->kind == EucCSSLayoutDocumentRunComponentKindHyphenationRule) {
                if (i == startComponentOffset) {
                    renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindString;
                    renderItem->item.stringItem.string = [(NSString *)info->component2 retain];
                    renderItem->item.stringItem.rect = CGRectMake(xPosition, yPosition + baseline - info->ascender, info->widthAfterHyphen, size.height);
                    renderItem->item.stringItem.pointSize = info->pointSize;
                    renderItem->item.stringItem.stringRenderer = [info->documentNode.stringRenderer retain];
                    renderItem->item.stringItem.layoutPoint = info->point;
                    ++renderItem;
                    ++_renderItemCount;
                    
                    xPosition += info->widthAfterHyphen;
                }
            } else if(info->kind == EucCSSLayoutDocumentRunComponentKindOpenNode) {
                checkForUnderline = YES;
                checkForHyperlink = YES;
            } else if(info->kind == EucCSSLayoutDocumentRunComponentKindCloseNode) {
                checkForUnderline = YES;
                checkForHyperlink = YES;
            }
        }
        
        // Stopping 'just before' a hyphen component really means that we stop
        // after the first part of the hyphenated word.
        if(i < documentRun.componentsCount) {
            if(info->kind == EucCSSLayoutDocumentRunComponentKindHyphenationRule) {
                --renderItem;
                
                xPosition -= info->width;
                
                // Store the entire word in the alt text for accessibility.
                renderItem->altText = renderItem->item.stringItem.string;
                
                renderItem->item.stringItem.string = [(NSString *)info->component retain];
                renderItem->item.stringItem.rect = CGRectMake(xPosition, yPosition + baseline - info->ascender, info->widthBeforeHyphen, size.height);
                renderItem->item.stringItem.layoutPoint = info->point;
                ++renderItem;                
            }
        }
        
        [currentHyperlink release];
    }
    return _renderItems;
}

- (NSComparisonResult)compare:(EucCSSLayoutPositionedLine *)rhs 
{
    return self < rhs ? NSOrderedAscending : (self > rhs ? NSOrderedDescending : NSOrderedSame);
}

@end
