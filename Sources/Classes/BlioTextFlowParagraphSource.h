//
//  BlioTextFlowParagraphSource.h
//  BlioApp
//
//  Created by James Montgomerie on 14/04/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioParagraphSource.h"

@class BlioTextFlow, BlioTextFlowFlowTree;

@interface BlioTextFlowParagraphSource : NSObject <BlioParagraphSource> {
    BlioTextFlow *textFlow;
    
    NSUInteger currentFlowTreeSection;
    BlioTextFlowFlowTree *currentFlowTree;
    
    float *sectionScaleFactors;
}

@property (nonatomic, retain) BlioTextFlow *textFlow;

- (id)initWithTextFlow:(BlioTextFlow *)textFlowIn;

@end
