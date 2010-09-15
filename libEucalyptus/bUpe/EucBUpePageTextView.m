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

#import "EucCSS.h"
#import "EucCSSIntermediateDocument.h"
#import "EucCSSIntermediateDocumentNode.h"
#import "EucCSSLayouter.h"
#import "EucCSSLayoutPositionedBlock.h"
#import "EucCSSRenderer.h"
#import "EucCSSLayoutPositionedRun.h"
#import "EucCSSLayoutPositionedLine.h"

#import "THPair.h"
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
        _scaleFactor = pointSize / EUC_CSS_DEFAULT_POINT_SIZE;
    }
    return self;
}

- (void)dealloc
{
    [_positionedBlock release];
    [_runs release];
    [_accessibilityElements release];
    [super dealloc];
}

- (void)setPointSize:(CGFloat)pointSize
{
    _pointSize = pointSize;
    _scaleFactor = pointSize / EUC_CSS_DEFAULT_POINT_SIZE;
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
    
    if(document) {
        EucCSSLayoutPoint layoutPoint;
        layoutPoint.nodeKey = point.block ?: document.rootNode.key;
        layoutPoint.word = point.word;
        layoutPoint.element = point.element;
        
        EucCSSLayouter *layouter = [[EucCSSLayouter alloc] initWithDocument:document
                                                                scaleFactor:_scaleFactor];
        
        BOOL isComplete = NO;
        positionedBlock = [layouter layoutFromPoint:layoutPoint
                                            inFrame:[self bounds]
                                 returningNextPoint:&layoutPoint
                                 returningCompleted:&isComplete];
        
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
    uint32_t lhsId = lhs.documentRun.id;
    uint32_t rhsId = rhs.documentRun.id;
    if(lhsId < rhsId) {
        return NSOrderedAscending;
    } else if (lhsId > rhsId) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (NSArray *)_runs
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
    return [[[self _runs] valueForKey:@"documentRun"] valueForKey:@"id"];
}

- (EucCSSLayoutPositionedRun *)_runWithKey:(uint32_t)key
{
    for(EucCSSLayoutPositionedRun *run in [self _runs]) {
        if(key == run.documentRun.id) {
            return run;
        }
    }
    return nil;
}

- (CGRect)frameOfBlockWithIdentifier:(id)blockId
{
    EucCSSLayoutPositionedRun *run = [self _runWithKey:[(NSNumber *)blockId intValue]];
    if(run) {
        return run.absoluteFrame;
    }
    return CGRectZero; 
}

- (NSArray *)identifiersForElementsOfBlockWithIdentifier:(id)blockId
{
    EucCSSLayoutPositionedRun *run = [self _runWithKey:[(NSNumber *)blockId intValue]];
    if(run) {
        NSMutableArray *array = [NSMutableArray array];
        uint32_t lastWordId = UINT32_MAX;

        for(EucCSSLayoutPositionedLine *line in run.children) {
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
    EucCSSLayoutPositionedRun *run = [self _runWithKey:[(NSNumber *)blockId intValue]];
    uint32_t wantedWordId = [(NSNumber *)elementId intValue];
    
    CGPoint runOrigin = run.absoluteFrame.origin;
    
    NSMutableArray *array = [NSMutableArray array];
    for(EucCSSLayoutPositionedLine *line in run.children) {
        EucCSSLayoutPositionedLineRenderItem* renderItems = line.renderItems;
        size_t renderItemsCount = line.renderItemCount;
        
        CGPoint lineOffset = line.frame.origin;
        lineOffset.x += runOrigin.x;
        lineOffset.y += runOrigin.y;
        
        EucCSSLayoutPositionedLineRenderItem* renderItem = renderItems;
        for(NSUInteger i = 0; i < renderItemsCount; ++i, ++renderItem) {
            if(renderItem->kind == EucCSSLayoutPositionedLineRenderItemKindString) {
                uint32_t wordId = renderItem->item.stringItem.layoutPoint.word;
                if(wordId == wantedWordId) {
                    CGRect itemRect = renderItem->item.stringItem.rect;
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
    
    EucCSSLayoutPositionedRun *run = [self _runWithKey:[(NSNumber *)blockId intValue]];
    uint32_t wantedWordId = [(NSNumber *)elementId intValue];
    
    
    for(EucCSSLayoutPositionedLine *line in run.children) {
        EucCSSLayoutPositionedLineRenderItem* renderItems = line.renderItems;
        size_t renderItemsCount = line.renderItemCount;
        EucCSSLayoutPositionedLineRenderItem* renderItem = renderItems;
        for(NSUInteger i = 0; i < renderItemsCount; ++i, ++renderItem) {
            if(renderItem->kind == EucCSSLayoutPositionedLineRenderItemKindString) {
                uint32_t wordId = renderItem->item.stringItem.layoutPoint.word;
                if(wordId == wantedWordId) {
                    if(renderItem->item.stringItem.layoutPoint.element == 0) {
                        word = renderItem->item.stringItem.string;
                    } else if(i != 0) {
                        // First part of a hyphenated word.  The full word
                        // is placed in the altText.
                        word = renderItem->altText;
                    }
                    break;
                } else if(wordId > wantedWordId) {
                    break;   
                }
            }
        }
    }    
    
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

        for(EucCSSLayoutPositionedRun *run in [self _runs]) {    
            CGPoint runOrigin = run.absoluteFrame.origin;
            for(EucCSSLayoutPositionedLine *line in run.children) {
                EucCSSLayoutPositionedLineRenderItem* renderItem = line.renderItems;
                size_t renderItemsCount = line.renderItemCount;
                
                CGPoint lineOffset = line.frame.origin;
                lineOffset.x += runOrigin.x;
                lineOffset.y += runOrigin.y;
                
                NSURL *currentHyperlinkURL = nil;
                CGRect hyperlinkRect = CGRectZero;
                for(size_t i = 0; i < renderItemsCount; ++i, ++renderItem) {
                    if(currentHyperlinkURL) {
                        if(renderItem->kind == EucCSSLayoutPositionedLineRenderItemKindString) {
                            if(CGRectIsEmpty(hyperlinkRect)) {
                                hyperlinkRect = CGRectOffset(renderItem->item.stringItem.rect, lineOffset.x, lineOffset.y);
                            } else {
                                hyperlinkRect = CGRectUnion(hyperlinkRect, 
                                                            CGRectOffset(renderItem->item.stringItem.rect, lineOffset.x, lineOffset.y));
                            }
                        } else if(renderItem->kind == EucCSSLayoutPositionedLineRenderItemKindImage) {
                            if(CGRectIsEmpty(hyperlinkRect)) {
                                hyperlinkRect = CGRectOffset(renderItem->item.imageItem.rect, lineOffset.x, lineOffset.y);
                            } else {
                                hyperlinkRect = CGRectUnion(hyperlinkRect, 
                                                            CGRectOffset(renderItem->item.imageItem.rect, lineOffset.x, lineOffset.y));
                            }
                        } else if(renderItem->kind == EucCSSLayoutPositionedLineRenderItemKindHyperlinkStop) {
                            NSParameterAssert([renderItem->item.hyperlinkItem.url isEqual:currentHyperlinkURL]);
                            [buildHyperlinkRectAndURLPairs addPairWithFirst:[NSValue valueWithCGRect:hyperlinkRect]
                                                                second:currentHyperlinkURL];
                            currentHyperlinkURL = nil;
                        }
                    } else {
                        if(renderItem->kind == EucCSSLayoutPositionedLineRenderItemKindHyperlinkStart) {
                            currentHyperlinkURL = renderItem->item.hyperlinkItem.url;
                        }
                    }
                }
                if(currentHyperlinkURL) {
                    // Line ended with unclosed hyperlink
                    [buildHyperlinkRectAndURLPairs addPairWithFirst:[NSValue valueWithCGRect:hyperlinkRect]
                                                        second:currentHyperlinkURL];
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

- (void)handleTouchEnded:(UITouch *)touch atLocation:(CGPoint)location 
{
    if(touch == _touch)  {
        if(_touchHyperlinkIndex != NSUIntegerMax) {
            NSUInteger newTouchHyperlinkIndex = [self _hyperlinkIndexForPoint:location];
            if(newTouchHyperlinkIndex == _touchHyperlinkIndex) {
                id<EucPageTextViewDelegate> myDelegate = self.delegate;
                if([myDelegate respondsToSelector:@selector(pageTextView:didReceiveTapOnHyperlinkWithURL:)]) {
                    [myDelegate pageTextView:self 
             didReceiveTapOnHyperlinkWithURL:((THPair *)[[self _hyperlinkRectAndURLPairs] objectAtIndex:_touchHyperlinkIndex]).second];
                }
            }
        }
        _touch = nil;
    }
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
        NSArray *runs = [self _runs];
        
        NSMutableArray *buildAccessibilityElements = [[NSMutableArray alloc] initWithCapacity:runs.count];
        
        CGRect buildElementFrame = CGRectZero;
        UIAccessibilityTraits buildElementTraits = UIAccessibilityTraitStaticText;
        NSMutableString *buildElementString = [NSMutableString string];
        
        CGRect itemFrame = CGRectZero;
        
        for(EucCSSLayoutPositionedRun *run in runs) {
            CGPoint runOrigin = run.absoluteFrame.origin;
            runOrigin.x += myFrame.origin.x;
            runOrigin.y += myFrame.origin.y;
            for(EucCSSLayoutPositionedLine *line in run.children) {
                CGPoint lineOffset = line.frame.origin;
                lineOffset.x += runOrigin.x;
                lineOffset.y += runOrigin.y;                
                
                EucCSSLayoutPositionedLineRenderItem* renderItems = line.renderItems;
                size_t renderItemsCount = line.renderItemCount;
                
                EucCSSLayoutPositionedLineRenderItem* renderItem = renderItems;
                for(NSUInteger i = 0; i < renderItemsCount; ++i, ++renderItem) {                    
                    if(renderItem->kind == EucCSSLayoutPositionedLineRenderItemKindString) {
                        if(buildElementString.length) {
                            [buildElementString appendString:@" "];
                        }
                        if(renderItem->item.stringItem.layoutPoint.element == 0) {
                            [buildElementString appendString:renderItem->item.stringItem.string];
                        } else if(i != 0) {
                            // First part of a hyphenated word.  The full word
                            // is placed in the altText.
                            [buildElementString appendString:renderItem->altText];
                        }
                        itemFrame = renderItem->item.stringItem.rect;
                    } else if(renderItem->kind == EucCSSLayoutPositionedLineRenderItemKindImage) {
                        if(buildElementString.length) {
                            [self _addAccessibilityElementTo:buildAccessibilityElements
                                                      string:buildElementString
                                                        rect:buildElementFrame
                                                      traits:buildElementTraits];
                            [buildElementString setString:@""];
                            buildElementFrame = CGRectZero;
                        }
                        [self _addAccessibilityElementTo:buildAccessibilityElements
                                                  string:renderItem->altText
                                                    rect:CGRectOffset(renderItem->item.imageItem.rect, lineOffset.x, lineOffset.y)
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

@end
