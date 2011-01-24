//
//  EucCSSLayoutSizedContainer.m
//  libEucalyptus
//
//  Created by James Montgomerie on 11/01/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutSizedContainer.h"

#import "EucCSSLayoutSizedRun.h"
#import "EucCSSLayoutSizedBlock.h"
#import "EucCSSLayoutSizedTable.h"

#import "EucCSSLayoutPositionedContainer.h"
#import "EucCSSLayoutPositionedRun.h"
#import "EucCSSLayoutPositionedBlock.h"
#import "EucCSSLayoutPositionedTable.h"

@implementation EucCSSLayoutSizedContainer

@synthesize children = _children;

- (id)initWithScaleFactor:(CGFloat)scaleFactor;
{
    if((self = [super initWithScaleFactor:scaleFactor])) {
        _children = [[NSMutableArray alloc] init];
    }    
    return self;
}

- (void)dealloc
{
    [_children release];
    
    [super dealloc];
}

- (void)addChild:(EucCSSLayoutSizedEntity *)child
{
    [_children addObject:child];
    child.parent = self;
}

- (CGFloat)minWidth
{
    return ceilf([[_children valueForKeyPath:@"@max.minWidth"] floatValue]);
}

- (CGFloat)maxWidth
{
    return ceilf([[_children valueForKeyPath:@"@max.maxWidth"] floatValue]);
}

- (void)positionChildrenInContainer:(EucCSSLayoutPositionedContainer *)positionedContainer usingLayouter:(EucCSSLayouter *)layouter
{
    CGRect contentBounds = positionedContainer.contentBounds;
    
    for(EucCSSLayoutSizedEntity *child in self.children) {
        // TODO: refactor the child classes here so that we can just call
        // one method, not switch.
        EucCSSLayoutPositionedContainer *positionedChild = nil;
        if([child isKindOfClass:[EucCSSLayoutSizedTable class]]){
            EucCSSLayoutSizedTable *table = (EucCSSLayoutSizedTable *)child;
            positionedChild = [table positionTableForFrame:contentBounds
                                               inContainer:positionedContainer
                                             usingLayouter:layouter];
        } else if([child isKindOfClass:[EucCSSLayoutSizedBlock class]]) {
            EucCSSLayoutSizedBlock *block = (EucCSSLayoutSizedBlock *)child;
            positionedChild = [block positionBlockForFrame:contentBounds
                                               inContainer:positionedContainer
                                             usingLayouter:layouter];
        } else if([child isKindOfClass:[EucCSSLayoutSizedRun class]]) {
            EucCSSLayoutSizedRun *run = (EucCSSLayoutSizedRun *)child;
            positionedChild = [run positionRunForFrame:contentBounds
                                           inContainer:positionedContainer 
                                  startingAtWordOffset:0
                                         elementOffset:0
                                usingLayouterForFloats:layouter];
        }
        contentBounds.origin.y += positionedChild.frame.size.height;
    }
    
    [positionedContainer closeBottomWithContentHeight:contentBounds.origin.y];
}

@end
