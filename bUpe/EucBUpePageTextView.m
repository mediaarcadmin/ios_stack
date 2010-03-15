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

#import "EucCSSIntermediateDocument.h"
#import "EucCSSIntermediateDocumentNode.h"
#import "EucCSSLayouter.h"
#import "EucCSSLayoutPositionedBlock.h"
#import "EucCSSRenderer.h"
#import "EucCSSLayoutPositionedBlock.h"

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
    }
    return self;
}

- (void)dealloc
{
    [_positionedBlock release];
    [super dealloc];
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
        
        EucCSSLayouter *layouter = [[EucCSSLayouter alloc] init];
        layouter.document = document;
        
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

- (NSArray *)blockIdentifiers
{
    return nil;
}

- (CGRect)frameOfBlockWithIdentifier:(id)blockId
{
    return CGRectZero;
}

- (NSArray *)identifiersForElementsOfBlockWithIdentifier:(id)id
{
    return nil;
}

- (NSArray *)rectsForElementWithIdentifier:(id)elementId ofBlockWithIdentifier:(id)blockId
{
    return nil;
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

- (void)handleTouchBegan:(UITouch *)touch atLocation:(CGPoint)location {}
- (void)handleTouchMoved:(UITouch *)touch atLocation:(CGPoint)location {}
- (void)handleTouchEnded:(UITouch *)touch atLocation:(CGPoint)location {}
- (void)handleTouchCancelled:(UITouch *)touch atLocation:(CGPoint)location {}

@end
