//
//  MSTapDetector.m
//  TapTurningDemo
//
//  Created by David Keay on 1/3/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MSTapDetector.h"

// Constant for maximum acceleration.
#define kMaxAcceleration 3.0
// Constant for the high-pass filter.
#define kFilteringFactor 0.3

#define kTapThreshold 0.3


#define kAccelerometerFrequency     10

// GraphView class implementation.
@implementation MSTapDetector

// Instruct the compiler to generate accessors for the property, and use the internal variable _filter for storage.

@synthesize timeOfFirstSpike, numSpikes, signOfFirstSpike, timeOfLastPageTurn;
@synthesize feedbackLabel;

- (id)init {
    self = [super init];
    numSpikes = 0;
    timeOfFirstSpike = 0;
    timeOfLastPageTurn = 0; 
    signOfFirstSpike = 0;
    
    return self;
}

- (void)clearSpikeHistory {
    [clearSpikeTimer invalidate];
    clearSpikeTimer = nil;
    numSpikes = 0;
    timeOfFirstSpike = 0;
    
}

- (void)updateHistoryWithX:(float)x Y:(float)y Z:(float)z {

    

    acceleration[0] = x * kFilteringFactor + acceleration[0] * (1.0 - kFilteringFactor);
    history[nextIndex][0] = x - acceleration[0];
    acceleration[1] = y * kFilteringFactor + acceleration[1] * (1.0 - kFilteringFactor);
    history[nextIndex][1] = y - acceleration[1];
    acceleration[2] = z * kFilteringFactor + acceleration[2] * (1.0 - kFilteringFactor);
    history[nextIndex][2] = z - acceleration[2];

    

    float xValue = history[nextIndex][2];
    
    
    if (xValue > kTapThreshold || xValue < -kTapThreshold) {
        NSTimeInterval newSpikeTime = [NSDate timeIntervalSinceReferenceDate];

        if (newSpikeTime - timeOfLastPageTurn < 1.0) return;
        
        if (numSpikes == 0) {
            timeOfFirstSpike = [NSDate timeIntervalSinceReferenceDate];
            numSpikes = 1;
            signOfFirstSpike = xValue > 0 ? 1 : -1;
            clearSpikeTimer = [NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(clearSpikeHistory) userInfo:nil repeats:NO];
            
            
        } else {
            if (signOfFirstSpike * xValue < 0) {
                signOfFirstSpike = xValue > 0 ? 1 : -1;
                numSpikes++;
            }
            
            if (numSpikes > 1) {

                timeOfLastPageTurn = [NSDate timeIntervalSinceReferenceDate]; 
                if (signOfFirstSpike == 1) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"TapToNextPage" object:self userInfo:nil];
                } else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"TapToNextPage" object:self userInfo:nil];                    
                }

                numSpikes = 0;
                timeOfFirstSpike = 0;
                signOfFirstSpike = 0;
                timeOfLastPageTurn = [NSDate timeIntervalSinceReferenceDate];

                
            }
          
        }
    }
    
    // Advance buffer pointer to next position or reset to zero.
    nextIndex = (nextIndex + 1) % kHistorySize;
    
    
    
}


@end

