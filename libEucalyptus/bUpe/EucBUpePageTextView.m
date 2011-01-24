//
//  EucBUpePageTextView.m
//  libEucalyptus
//
//  Created by James Montgomerie on 12/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucBUpePageTextView.h"
#import "EucBUpeBook.h"

#import "EucBookPageIndexPoint.h"

#import "EucConfiguration.h"
#import "EucCSSIntermediateDocument.h"
#import "EucCSSIntermediateDocumentNode.h"
#import "EucCSSLayouter.h"
#import "EucCSSLayoutPositionedBlock.h"
#import "EucCSSRenderer.h"
#import "EucCSSLayoutSizedRun.h"
#import "EucCSSLayoutPositionedRun.h"
#import "EucCSSLayoutPositionedLine.h"

#import "THPair.h"
#import "THLog.h"
#import "THGeometryUtils.h"

@interface EucBUpePageTextView ()
    
@property (nonatomic, retain) EucCSSLayoutPositionedBlock *positionedBlock;

@end


@implementation EucBUpePageTextView

@synthesize delegate = _delegate;
@synthesize pointSize = _pointSize;
@synthesize allowScaledImageDistortion = _allowScaledImageDistortion;

@synthesize positionedBlock = _positionedBlock;

- (id)initWithFrame:(CGRect)frame pointSize:(CGFloat)pointSize
{
    if((self = [super initWithFrame:frame])) {
        _pointSize = pointSize;
        _scaleFactor = pointSize / [[EucConfiguration objectForKey:EucConfigurationDefaultFontSizeKey] floatValue];
    }
    return self;
}

- (void)dealloc
{
    [_positionedBlock release];
    [_runs release];
    [_accessibilityElements release];
	[_hyperlinkRectAndURLPairs release];
    [super dealloc];
}

- (void)setPointSize:(CGFloat)pointSize
{
    _pointSize = pointSize;
    _scaleFactor = pointSize / [[EucConfiguration objectForKey:EucConfigurationDefaultFontSizeKey] floatValue];
}

- (EucBookPageIndexPoint *)layoutPageFromPoint:(EucBookPageIndexPoint *)point
                                        inBook:(id<EucBook>)bookIn
                                  centerOnPage:(BOOL)centerOnPage
{
    EucBookPageIndexPoint *ret = nil;
    EucBUpeBook *book = (EucBUpeBook *)bookIn;
    
    EucCSSIntermediateDocument *document = [book intermediateDocumentForIndexPoint:point];
    EucCSSLayoutPositionedBlock *positionedBlock = nil;
    self.positionedBlock = nil;
    
    //THLog(@"Laying Out From: %@", point);
    
    if(document) {
        EucCSSLayoutPoint layoutPoint;
        layoutPoint.nodeKey = point.block ?: document.rootNode.key;
        layoutPoint.word = point.word;
        layoutPoint.element = point.element;
        
        EucCSSLayouter *layouter = [[EucCSSLayouter alloc] initWithDocument:document];
        
        BOOL isComplete = NO;
        positionedBlock = [layouter layoutFromPoint:layoutPoint
                                            inFrame:[self bounds]
                                 returningNextPoint:&layoutPoint
                                 returningCompleted:&isComplete
                                        scaleFactor:_scaleFactor * book.normalisingScaleFactor];
        
        if(isComplete) {
            ret = [[EucBookPageIndexPoint alloc] init];
            ret.source = point.source + 1;
            if(![book intermediateDocumentForIndexPoint:point]) {
                [ret release];
                ret = nil;
            }
        } else {
            ret = [[EucBookPageIndexPoint alloc] init];
            ret.source = point.source;
            ret.block = layoutPoint.nodeKey;
            ret.word = layoutPoint.word;
            ret.element = layoutPoint.element;
        }    
        
        [layouter release];
        
        if(centerOnPage && positionedBlock) {
            [positionedBlock shrinkToFit];
            CGRect bounds = self.bounds;
            CGRect blockFrame = positionedBlock.frame;
            blockFrame.origin.x = bounds.origin.x + floor((bounds.size.width - blockFrame.size.width) * 0.5f);
            blockFrame.origin.y = bounds.origin.y + floor((bounds.size.height - blockFrame.size.height) * 0.5f);
            positionedBlock.frame = blockFrame;
        }
    }
    
    self.positionedBlock = positionedBlock;
    
    //THLog(@"Layed out to: %@", ret);
    
    return [ret autorelease];
}

- (EucBookPageIndexPoint *)layoutPageFromPoint:(EucBookPageIndexPoint *)point
                                        inBook:(id<EucBook>)bookIn
{
    return [self layoutPageFromPoint:point inBook:bookIn centerOnPage:NO];
}

- (void)_accumulateRunsBelow:(EucCSSLayoutPositionedContainer *)block intoArray:(NSMutableArray *)array
{
    if([block isKindOfClass:[EucCSSLayoutPositionedRun class]]) {
        [array addObject:block];
    } else {
        for(EucCSSLayoutPositionedContainer * subBlock in ((EucCSSLayoutPositionedBlock *)block).leftFloatChildren) {
            [self _accumulateRunsBelow:subBlock intoArray:array];   
        }
        for(EucCSSLayoutPositionedContainer * subBlock in block.children) {
            [self _accumulateRunsBelow:subBlock intoArray:array];   
        }
        for(EucCSSLayoutPositionedContainer * subBlock in ((EucCSSLayoutPositionedBlock *)block).rightFloatChildren) {
            [self _accumulateRunsBelow:subBlock intoArray:array];   
        } 
    }
}

static NSComparisonResult runCompare(EucCSSLayoutPositionedRun *lhs, EucCSSLayoutPositionedRun *rhs, void *context) {
    uint32_t lhsId = lhs.sizedRun.run.id;
    uint32_t rhsId = rhs.sizedRun.run.id;
    if(lhsId < rhsId) {
        return NSOrderedAscending;
    } else if (lhsId > rhsId) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (NSArray *)_positionedRuns
{
    if(!_runs) {
        _runs = [[NSMutableArray alloc] init];
        [self _accumulateRunsBelow:self.positionedBlock intoArray:(NSMutableArray *)_runs];
        [(NSMutableArray *)_runs sortUsingFunction:(NSInteger (*)(id, id, void *))runCompare context:NULL];
    }
    return _runs;
}

- (NSArray *)blockIdentifiers
{
    return [[[[self _positionedRuns] valueForKey:@"sizedRun"]  valueForKey:@"run"] valueForKey:@"id"];
}

- (EucCSSLayoutPositionedRun *)_positionedRunWithKey:(uint32_t)key
{
    for(EucCSSLayoutPositionedRun *positionedRun in [self _positionedRuns]) {
        if(key == positionedRun.sizedRun.run.id) {
            return positionedRun;
        }
    }
    return nil;
}

- (CGRect)frameOfBlockWithIdentifier:(id)blockId
{
    EucCSSLayoutPositionedRun *positionedRun = [self _positionedRunWithKey:[(NSNumber *)blockId intValue]];
    if(positionedRun) {
        return positionedRun.absoluteFrame;
    }
    return CGRectZero; 
}

- (NSArray *)identifiersForElementsOfBlockWithIdentifier:(id)blockId
{
    EucCSSLayoutPositionedRun *positionedRun = [self _positionedRunWithKey:[(NSNumber *)blockId intValue]];
    if(positionedRun) {
        NSMutableArray *array = [NSMutableArray array];
        uint32_t lastWordId = UINT32_MAX;

        for(EucCSSLayoutPositionedLine *line in positionedRun.children) {
            EucCSSLayoutPositionedLineRenderItem* renderItems = line.renderItems;
            size_t renderItemsCount = line.renderItemCount;
            
            EucCSSLayoutPositionedLineRenderItem* renderItem = renderItems;
            for(NSUInteger i = 0; i < renderItemsCount; ++i, ++renderItem) {
                if(renderItem->kind == EucCSSLayoutPositionedLineRenderItemKindString) {
                    uint32_t wordId = renderItem->item.stringItem.layoutPoint.word;
                    if(wordId != lastWordId) {
                        [array addObject:[NSNumber numberWithUnsignedInt:wordId]];
                        lastWordId = wordId;
                    }
                }
            }
        }
        return array;
    }
    return nil;
}

- (NSArray *)rectsForElementWithIdentifier:(id)elementId ofBlockWithIdentifier:(id)blockId
{
    EucCSSLayoutPositionedRun *positionedRun = [self _positionedRunWithKey:[(NSNumber *)blockId intValue]];
    uint32_t wantedWordId = [(NSNumber *)elementId intValue];
    
    CGPoint runOrigin = positionedRun.absoluteFrame.origin;
    
    NSMutableArray *array = [NSMutableArray array];
    for(EucCSSLayoutPositionedLine *line in positionedRun.children) {
        EucCSSLayoutPositionedLineRenderItem* renderItems = line.renderItems;
        size_t renderItemsCount = line.renderItemCount;
        
        CGPoint lineOffset = line.frame.origin;
        lineOffset.x += runOrigin.x;
        lineOffset.y += runOrigin.y;
        
        CGPoint currentAbsoluteOrigin = CGPointZero;
        
        EucCSSLayoutPositionedLineRenderItem* renderItem = renderItems;
        for(NSUInteger i = 0; i < renderItemsCount; ++i, ++renderItem) {
            if(renderItem->kind == EucCSSLayoutPositionedLineRenderItemKindOpenNode) {
                currentAbsoluteOrigin.x += renderItem->origin.x;
                currentAbsoluteOrigin.y += renderItem->origin.y;
            } else if(renderItem->kind == EucCSSLayoutPositionedLineRenderItemKindCloseNode) {
                if(renderItem->parentIndex != NSUIntegerMax) {
                    EucCSSLayoutPositionedLineRenderItem* parentItem = renderItems + renderItem->parentIndex;
                    currentAbsoluteOrigin.x -= parentItem->origin.x;
                    currentAbsoluteOrigin.y -= parentItem->origin.y;
                }
            } else if(renderItem->kind == EucCSSLayoutPositionedLineRenderItemKindString) {
                uint32_t wordId = renderItem->item.stringItem.layoutPoint.word;
                if(wordId == wantedWordId) {
                    CGRect itemRect = CGRectMake(currentAbsoluteOrigin.x + renderItem->origin.x,
                                                 currentAbsoluteOrigin.y + renderItem->origin.y, 
                                                 renderItem->lineBox.width, 
                                                 renderItem->lineBox.height);
                    itemRect.origin.x += lineOffset.x;
                    itemRect.origin.y += lineOffset.y;
                    [array addObject:[NSValue valueWithCGRect:itemRect]];
                } else if(wordId > wantedWordId) {
                    break;   
                }
            }
        }
    }    
    return array.count ? array : nil;
}

- (NSString *)accessibilityLabelForElementWithIdentifier:(id)elementId ofBlockWithIdentifier:(id)blockId
{
    NSString *word = nil; 
    
    EucCSSLayoutPositionedRun *positionedRun = [self _positionedRunWithKey:[(NSNumber *)blockId intValue]];
    uint32_t wantedWordId = [(NSNumber *)elementId intValue];
    
    for(EucCSSLayoutPositionedLine *line in positionedRun.children) {
        EucCSSLayoutPositionedLineRenderItem* renderItems = line.renderItems;
        size_t renderItemsCount = line.renderItemCount;
        EucCSSLayoutPositionedLineRenderItem* renderItem = renderItems;
        for(NSUInteger i = 0; i < renderItemsCount; ++i, ++renderItem) {
            if(renderItem->kind == EucCSSLayoutPositionedLineRenderItemKindString) {
                uint32_t wordId = renderItem->item.stringItem.layoutPoint.word;
                if(wordId == wantedWordId) {
                    if(renderItem->item.stringItem.layoutPoint.element == 0) {
                        word = renderItem->item.stringItem.string;
                    } else if(renderItem->altText) {
                        // First part of a hyphenated word.  The full word
                        // is placed in the altText.
                        word = renderItem->altText;
                    }
                    goto found;
                } else if(wordId > wantedWordId) {
                    goto found;   
                }
            }
        }
    }    
found:
    return word;
}

- (void)clear
{
    [_positionedBlock release];
    _positionedBlock = nil;
}

- (void)drawRect:(CGRect)rect inContext:(CGContextRef)cgContext
{
    EucCSSLayoutPositionedBlock *positionedBlock = self.positionedBlock;
    if(positionedBlock) {
        EucCSSRenderer *renderer = [[EucCSSRenderer alloc] init];
        renderer.cgContext = cgContext;
        [renderer render:self.positionedBlock atPoint:CGPointZero];
        [renderer release];
    }
}

- (void)drawRect:(CGRect)rect 
{
    [self drawRect:rect inContext:UIGraphicsGetCurrentContext()];
}

- (NSArray *)_hyperlinkRectAndURLPairs
{
    if(!_hyperlinkRectAndURLPairs) {
        NSMutableArray *buildHyperlinkRectAndURLPairs = [[NSMutableArray alloc] init];

        for(EucCSSLayoutPositionedRun *positionedRun in [self _positionedRuns]) {    
            CGPoint runOrigin = positionedRun.absoluteFrame.origin;
            for(EucCSSLayoutPositionedLine *line in positionedRun.children) {
                EucCSSLayoutPositionedLineRenderItem* renderItems = line.renderItems;
                EucCSSLayoutPositionedLineRenderItem* renderItem = renderItems;
                size_t renderItemsCount = line.renderItemCount;
                
                CGPoint lineOffset = line.frame.origin;
                lineOffset.x += runOrigin.x;
                lineOffset.y += runOrigin.y;
                
                CGPoint currentAbsoluteOrigin = CGPointZero;
                
                EucCSSIntermediateDocumentNode *currentHyperlinkNode = nil;
                CGRect currentHyperlinkRect = CGRectZero;
                for(size_t i = 0; i < renderItemsCount; ++i, ++renderItem) {
                    if(currentHyperlinkNode) {
                        if(renderItem->kind == EucCSSLayoutPositionedLineRenderItemKindString) {
                            CGRect itemRect = CGRectMake(currentAbsoluteOrigin.x + renderItem->origin.x,
                                                         currentAbsoluteOrigin.y + renderItem->origin.y, 
                                                         renderItem->lineBox.width, 
                                                         renderItem->lineBox.height);                            
                            if(CGRectIsEmpty(currentHyperlinkRect)) {
                                currentHyperlinkRect = CGRectOffset(itemRect, lineOffset.x, lineOffset.y);
                            } else {
                                currentHyperlinkRect = CGRectUnion(currentHyperlinkRect, CGRectOffset(itemRect, lineOffset.x, lineOffset.y));
                            }
                        } else if(renderItem->kind == EucCSSLayoutPositionedLineRenderItemKindImage) {
                            CGRect itemRect = CGRectMake(currentAbsoluteOrigin.x + renderItem->origin.x,
                                                          currentAbsoluteOrigin.y + renderItem->origin.y, 
                                                          renderItem->lineBox.width, 
                                                          renderItem->lineBox.height);
                            
                            if(CGRectIsEmpty(currentHyperlinkRect)) {
                                currentHyperlinkRect = CGRectOffset(itemRect, lineOffset.x, lineOffset.y);
                            } else {
                                currentHyperlinkRect = CGRectUnion(currentHyperlinkRect, CGRectOffset(itemRect, lineOffset.x, lineOffset.y));
                            }
                        } 
                    }
                    if(renderItem->kind == EucCSSLayoutPositionedLineRenderItemKindCloseNode) {
                        if(renderItem->item.closeNodeInfo.node == currentHyperlinkNode) {
                            [buildHyperlinkRectAndURLPairs addPairWithFirst:[NSValue valueWithCGRect:currentHyperlinkRect]
                                                                     second:currentHyperlinkNode.hyperlinkURL];
                            currentHyperlinkNode = nil;
                            currentHyperlinkRect = CGRectZero;
                        }
                        if(renderItem->parentIndex != NSUIntegerMax) {
                            EucCSSLayoutPositionedLineRenderItem* parentItem = renderItems + renderItem->parentIndex;
                            currentAbsoluteOrigin.x -= parentItem->origin.x;
                            currentAbsoluteOrigin.y -= parentItem->origin.y;       
                        }
                    } else if(renderItem->kind == EucCSSLayoutPositionedLineRenderItemKindOpenNode) {
                        if(renderItem->item.openNodeInfo.node.isHyperlinkNode) {
                            currentHyperlinkNode = renderItem->item.openNodeInfo.node;
                        }
                        currentAbsoluteOrigin.x += renderItem->origin.x;
                        currentAbsoluteOrigin.y += renderItem->origin.y;
                    }
                }
            }
        }
        
        _hyperlinkRectAndURLPairs = buildHyperlinkRectAndURLPairs;
    } 
    return _hyperlinkRectAndURLPairs;
}

- (NSUInteger)_hyperlinkIndexForPoint:(CGPoint)point
{
    CGFloat bestDistance = CGFLOAT_MAX;
    NSUInteger bestCandidate = NSUIntegerMax;
    NSUInteger i = 0;
    for(THPair *rectAndURL in [self _hyperlinkRectAndURLPairs]) {
        CGFloat distance = CGPointDistanceFromRect(point, [rectAndURL.first CGRectValue]);
        if(distance < bestDistance) {
            bestDistance = distance;
            bestCandidate = i;
        }
        ++i;
    }
    if(bestDistance < 10.0f) {
        return bestCandidate;
    } else {
        return NSUIntegerMax;
    }
}

- (void)handleTouchBegan:(UITouch *)touch atLocation:(CGPoint)location 
{
    if(!_touch)  {
        _touch = touch;
        _touchHyperlinkIndex = [self _hyperlinkIndexForPoint:location];
    }
}

- (void)handleTouchMoved:(UITouch *)touch atLocation:(CGPoint)location { }

- (BOOL)handleTouchEnded:(UITouch *)touch atLocation:(CGPoint)location 
{
    BOOL ret = NO;
    if(touch == _touch)  {
        if(_touchHyperlinkIndex != NSUIntegerMax) {
            NSUInteger newTouchHyperlinkIndex = [self _hyperlinkIndexForPoint:location];
            if(newTouchHyperlinkIndex == _touchHyperlinkIndex) {
                id<EucPageTextViewDelegate> myDelegate = self.delegate;
                if([myDelegate respondsToSelector:@selector(pageTextView:didReceiveTapOnHyperlinkWithURL:)]) {
                    [myDelegate pageTextView:self 
             didReceiveTapOnHyperlinkWithURL:((THPair *)[[self _hyperlinkRectAndURLPairs] objectAtIndex:_touchHyperlinkIndex]).second];
                    
                    ret = YES;
                }
            }
        }
        _touch = nil;
    }
    return ret;
}

- (void)handleTouchCancelled:(UITouch *)touch atLocation:(CGPoint)location 
{
    if(touch == _touch)  {
        _touch = nil;
    }    
}

- (CGRect)contentRect
{
    return _positionedBlock.frame;
}

#pragma mark -
#pragma mark Accessibility

- (void)_addAccessibilityElementTo:(NSMutableArray *)array
                            string:(NSString *)string
                              rect:(CGRect)rect
                            traits:(UIAccessibilityTraits)traits
{
    UIAccessibilityElement *element = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
    element.accessibilityFrame = rect;
    NSString *labelString = [string copy];
    element.accessibilityLabel = labelString;
    [labelString release];
    element.accessibilityTraits = traits;
    [array addObject:element];
    [element release];
}


- (NSArray *)accessibilityElements
{
    if(!_accessibilityElements) {
        CGRect myFrame = self.frame;
        NSArray *positionedRuns = [self _positionedRuns];
        
        NSMutableArray *buildAccessibilityElements = [[NSMutableArray alloc] initWithCapacity:positionedRuns.count];
        
        CGRect buildElementFrame = CGRectZero;
        UIAccessibilityTraits buildElementTraits = UIAccessibilityTraitStaticText;
        NSMutableString *buildElementString = [NSMutableString string];
        
        CGRect itemFrame = CGRectZero;
        
        for(EucCSSLayoutPositionedRun *positionedRun in positionedRuns) {
            CGPoint runOrigin = positionedRun.absoluteFrame.origin;
            runOrigin.x += myFrame.origin.x;
            runOrigin.y += myFrame.origin.y;
            for(EucCSSLayoutPositionedLine *line in positionedRun.children) {
                CGPoint lineOffset = line.frame.origin;
                lineOffset.x += runOrigin.x;
                lineOffset.y += runOrigin.y;                
                
                CGPoint currentAbsoluteOrigin = CGPointZero;
                
                EucCSSLayoutPositionedLineRenderItem* renderItems = line.renderItems;
                size_t renderItemsCount = line.renderItemCount;
                
                EucCSSLayoutPositionedLineRenderItem* renderItem = renderItems;
                for(NSUInteger i = 0; i < renderItemsCount; ++i, ++renderItem) {   
                    if(renderItem->kind == EucCSSLayoutPositionedLineRenderItemKindOpenNode) {
                        currentAbsoluteOrigin.x += renderItem->origin.x;
                        currentAbsoluteOrigin.y += renderItem->origin.y;
                    } else if(renderItem->kind == EucCSSLayoutPositionedLineRenderItemKindCloseNode) {
                        if(renderItem->parentIndex != NSUIntegerMax) {
                            EucCSSLayoutPositionedLineRenderItem* parentItem = renderItems + renderItem->parentIndex;
                            currentAbsoluteOrigin.x -= parentItem->origin.x;
                            currentAbsoluteOrigin.y -= parentItem->origin.y;
                        }
                    } else if(renderItem->kind == EucCSSLayoutPositionedLineRenderItemKindString) {
                        if(buildElementString.length) {
                            [buildElementString appendString:@" "];
                        }
                        if(renderItem->item.stringItem.layoutPoint.element == 0) {
                            [buildElementString appendString:renderItem->item.stringItem.string];
                        } else if(renderItem->altText) {
                            // First part of a hyphenated word.  The full word
                            // is placed in the altText.
                            [buildElementString appendString:renderItem->altText];
                        }
                        itemFrame = CGRectMake(currentAbsoluteOrigin.x + renderItem->origin.x,
                                               currentAbsoluteOrigin.y + renderItem->origin.y, 
                                               renderItem->lineBox.width, 
                                               renderItem->lineBox.height);
                    } else if(renderItem->kind == EucCSSLayoutPositionedLineRenderItemKindImage) {
                        if(buildElementString.length) {
                            [self _addAccessibilityElementTo:buildAccessibilityElements
                                                      string:buildElementString
                                                        rect:buildElementFrame
                                                      traits:buildElementTraits];
                            [buildElementString setString:@""];
                            buildElementFrame = CGRectZero;
                        }
                        
                        CGRect imageRect = CGRectMake(currentAbsoluteOrigin.x + renderItem->origin.x,
                                                      currentAbsoluteOrigin.y + renderItem->origin.y, 
                                                      renderItem->lineBox.width, 
                                                      renderItem->lineBox.height);
                        
                        [self _addAccessibilityElementTo:buildAccessibilityElements
                                                  string:renderItem->altText
                                                    rect:CGRectOffset(imageRect, lineOffset.x, lineOffset.y)
                                                  traits:buildElementTraits | UIAccessibilityTraitImage];
                    }
                    
                    if(!CGRectIsEmpty(itemFrame)) {
                        if(CGRectIsEmpty(buildElementFrame)) {
                            buildElementFrame = CGRectOffset(itemFrame, lineOffset.x, lineOffset.y);
                        } else {
                            buildElementFrame = CGRectUnion(buildElementFrame, CGRectOffset(itemFrame, lineOffset.x, lineOffset.y));
                        }
                        itemFrame = CGRectZero;
                    }
                }
            }
            if(buildElementString.length) {
                [self _addAccessibilityElementTo:buildAccessibilityElements
                                          string:buildElementString
                                            rect:buildElementFrame
                                          traits:buildElementTraits];
                [buildElementString setString:@""];
                buildElementFrame = CGRectZero;                
            }
        }
        
        _accessibilityElements = buildAccessibilityElements;
    }
    return _accessibilityElements;
}

- (BOOL)isAccessibilityElement
{
    return NO;
}

- (NSInteger)accessibilityElementCount
{
    return [[self accessibilityElements] count];
}

- (id)accessibilityElementAtIndex:(NSInteger)index
{
    return [[self accessibilityElements] objectAtIndex:index];
}

- (NSInteger)indexOfAccessibilityElement:(id)element
{
    return [[self accessibilityElements] indexOfObject:element];
}

- (NSString *)pageText
{
    NSArray *positionedRuns = [self _positionedRuns];    
    NSMutableString *buildPageText = [NSMutableString string];
    for(EucCSSLayoutPositionedRun *positionedRun in positionedRuns) {
        for(EucCSSLayoutPositionedLine *line in positionedRun.children) {
            EucCSSLayoutPositionedLineRenderItem* renderItems = line.renderItems;
            size_t renderItemsCount = line.renderItemCount;
            
            EucCSSLayoutPositionedLineRenderItem* renderItem = renderItems;
            for(NSUInteger i = 0; i < renderItemsCount; ++i, ++renderItem) {   
                if(renderItem->kind == EucCSSLayoutPositionedLineRenderItemKindString) {
                    if(buildPageText.length) {
                        [buildPageText appendString:@" "];
                    }
                    if(renderItem->item.stringItem.layoutPoint.element == 0) {
                        [buildPageText appendString:renderItem->item.stringItem.string];
                    } else if(renderItem->altText) {
                        // First part of a hyphenated word.  The full word
                        // is placed in the altText.
                        [buildPageText appendString:renderItem->altText];
                    }
                }
            }
        }
        [buildPageText appendString:@"\n"];
    }
    return buildPageText ?: nil;
}

@end
