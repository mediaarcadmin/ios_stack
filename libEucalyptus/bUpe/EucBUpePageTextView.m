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
#import "EucCSSLayoutLine.h"

#import "THPair.h"

@interface EucBUpePageTextView ()
    
@property (nonatomic, retain) EucCSSLayoutPositionedBlock *positionedBlock;

@end


@implementation EucBUpePageTextView

@synthesize delegate = _delegate;
@synthesize pointSize = _pointSize;
@synthesize allowScaledImageDistortion = _allowScaledImageDistortion;
@synthesize backgroundIsDark = _backgroundIsDark;

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
{
    EucBookPageIndexPoint *ret = nil;
    EucBUpeBook *book = (EucBUpeBook *)bookIn;
    
    EucCSSIntermediateDocument *document = [book intermediateDocumentForIndexPoint:point];
    
    if(document) {
        EucCSSLayoutPoint layoutPoint;
        layoutPoint.nodeKey = point.block ?: document.rootNode.key;
        layoutPoint.word = point.word;
        layoutPoint.element = point.element;
        
        EucCSSLayouter *layouter = [[EucCSSLayouter alloc] initWithDocument:document
                                                                scaleFactor:_scaleFactor];
        
        BOOL isComplete = NO;
        self.positionedBlock = [layouter layoutFromPoint:layoutPoint
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
    }
    return [ret autorelease];
}

- (void)_accumulateRunsBelowBlock:(EucCSSLayoutPositionedBlock *)block intoArray:(NSMutableArray *)array
{
    for(id subBlock in block.subEntities) {
        if([subBlock isKindOfClass:[EucCSSLayoutPositionedBlock class]]) {
            [self _accumulateRunsBelowBlock:(EucCSSLayoutPositionedBlock *)subBlock intoArray:array];
        } else if([subBlock isKindOfClass:[EucCSSLayoutPositionedRun class]]) {
            [array addObject:subBlock];
        }
    }
}

- (NSArray *)_runs
{
    if(!_runs) {
        _runs = [[NSMutableArray alloc] init];
        [self _accumulateRunsBelowBlock:self.positionedBlock intoArray:(NSMutableArray *)_runs];
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
        return run.frame;
    }
    return CGRectZero; 
}

- (NSArray *)identifiersForElementsOfBlockWithIdentifier:(id)blockId
{
    EucCSSLayoutPositionedRun *run = [self _runWithKey:[(NSNumber *)blockId intValue]];
    if(run) {
        NSMutableArray *array = [NSMutableArray array];
        uint32_t lastWordId = UINT32_MAX;

        for(EucCSSLayoutLine *line in run.lines) {
            EucCSSLayoutLineRenderItem* renderItems = line.renderItems;
            size_t renderItemsCount = line.renderItemCount;
            
            EucCSSLayoutLineRenderItem* renderItem = renderItems;
            for(NSUInteger i = 0; i < renderItemsCount; ++i, ++renderItem) {
                if([renderItem->item isKindOfClass:[NSString class]]) {
                    uint32_t wordId = renderItem->point.word;
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
    
    NSMutableArray *array = [NSMutableArray array];
    for(EucCSSLayoutLine *line in run.lines) {
        EucCSSLayoutLineRenderItem* renderItems = line.renderItems;
        size_t renderItemsCount = line.renderItemCount;
        
        EucCSSLayoutLineRenderItem* renderItem = renderItems;
        for(NSUInteger i = 0; i < renderItemsCount; ++i, ++renderItem) {
            if([renderItem->item isKindOfClass:[NSString class]]) {
                uint32_t wordId = renderItem->point.word;
                if(wordId == wantedWordId) {
                    [array addObject:[NSValue valueWithCGRect:renderItem->rect]];
                } else if(wordId > wantedWordId) {
                    break;   
                }
            }
        }
    }    
    return array.count ? array : nil;
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
        [renderer render:self.positionedBlock];
        [renderer release];
    }
}

- (void)drawRect:(CGRect)rect 
{
    [self drawRect:rect inContext:UIGraphicsGetCurrentContext()];
}

- (NSArray *)accessibilityElements
{
    if(!_accessibilityElements) {
        CGRect myFrame = self.frame;
        NSArray *runs = [self _runs];
        
        NSMutableArray *buildAccessibilityElements = [[NSMutableArray alloc] initWithCapacity:runs.count];
        for(EucCSSLayoutPositionedRun *run in runs) {
            UIAccessibilityElement *element = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
            
            CGRect frame = run.frame;
            frame.origin.x += myFrame.origin.x;
            frame.origin.y += myFrame.origin.y;
            element.accessibilityFrame = frame;
            
            NSMutableString *buildString = [NSMutableString string];
            for(EucCSSLayoutLine *line in run.lines) {
                EucCSSLayoutLineRenderItem* renderItems = line.renderItems;
                size_t renderItemsCount = line.renderItemCount;
                    
                EucCSSLayoutLineRenderItem* renderItem = renderItems;
                for(NSUInteger i = 0; i < renderItemsCount; ++i, ++renderItem) {
                    if(renderItem->altText) {
                        [buildString appendString:renderItem->altText];
                    } else if(renderItem->point.element == 0) {
                        [buildString appendString:renderItem->item];
                    }
                    [buildString appendString:@" "];
                }
            }
            NSUInteger stringLength = buildString.length;
            if(stringLength) {
                [buildString deleteCharactersInRange:NSMakeRange(stringLength - 1, 1)];
            }            
            element.accessibilityLabel = buildString;
            
            element.accessibilityTraits = UIAccessibilityTraitStaticText;
            
            [buildAccessibilityElements addObject:element];
            [element release];
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

- (void)handleTouchBegan:(UITouch *)touch atLocation:(CGPoint)location {}
- (void)handleTouchMoved:(UITouch *)touch atLocation:(CGPoint)location {}
- (void)handleTouchEnded:(UITouch *)touch atLocation:(CGPoint)location {}
- (void)handleTouchCancelled:(UITouch *)touch atLocation:(CGPoint)location {}

@end
