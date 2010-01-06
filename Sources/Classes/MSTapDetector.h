//
//  MSTapDetector.h
//  TapTurningDemo
//
//  Created by David Keay on 1/3/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AccelerometerFilter.h"


@interface MSTapDetector : NSObject
{
   
    NSTimeInterval timeOfFirstSpike;
    NSTimeInterval timeOfLastPageTurn;    
    int numSpikes;
    int signOfFirstSpike;
    float firstSpike;
    
    NSTimer *clearSpikeTimer;

    float rawInitialYValue;
    AccelerometerFilter *filter;
}



@property NSTimeInterval timeOfFirstSpike;
@property NSTimeInterval timeOfLastPageTurn;
@property int numSpikes;
@property int signOfFirstSpike;
//@property float firstSpike;
//@property float rawInitialYValue;

- (void)clearSpikeHistory;
- (void)updateFilterWithAcceleration:(UIAcceleration *)acceleration;

@end
