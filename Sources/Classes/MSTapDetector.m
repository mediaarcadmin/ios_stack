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

#define kTapThreshold 0.10


#define kAccelerometerFrequency     40

// GraphView class implementation.
@implementation MSTapDetector

// Instruct the compiler to generate accessors for the property, and use the internal variable _filter for storage.

@synthesize timeOfFirstSpike, numSpikes, signOfFirstSpike, timeOfLastPageTurn;


- (id)init {
    self = [super init];
    numSpikes = 0;
    timeOfFirstSpike = 0;
    timeOfLastPageTurn = 0; 
    signOfFirstSpike = 0;
    
    filter = [[HighpassFilter alloc] initWithSampleRate:40 cutoffFrequency:5.0];
    filter.adaptive = YES;
    return self;
}

- (void)clearSpikeHistory {
    [clearSpikeTimer invalidate];
    clearSpikeTimer = nil;
    numSpikes = 0;
    timeOfFirstSpike = 0;
    
}

- (void)updateFilterWithAcceleration:(UIAcceleration *)acc {
    
    
    [filter addAcceleration:acc];
    
    
    float value = filter.z;
    
    if (numSpikes == 1) {
        if (fabs(value) < .07 || !(value*signOfFirstSpike)) numSpikes++;
    }
    
    if (fabs(value) > kTapThreshold) {
        //we may have a tap!
        
        NSTimeInterval newSpikeTime = [NSDate timeIntervalSinceReferenceDate];
        if (newSpikeTime - timeOfLastPageTurn < 0.5) return;
        if (numSpikes == 0) {
            timeOfFirstSpike = [NSDate timeIntervalSinceReferenceDate];
            numSpikes = 1;
            signOfFirstSpike = value > 0 ? 1 : -1;
            clearSpikeTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(clearSpikeHistory) userInfo:nil repeats:NO];
        } else {
            if (signOfFirstSpike * value > 0 && numSpikes == 2) {
                //They tapped properly! Turn the page!
                [[NSNotificationCenter defaultCenter] postNotificationName:@"TapToNextPage" object:self userInfo:nil];
                
                numSpikes = 0;
                timeOfFirstSpike = 0;
                signOfFirstSpike = 0;
                timeOfLastPageTurn = [NSDate timeIntervalSinceReferenceDate];
                if (clearSpikeTimer) {
                    [clearSpikeTimer invalidate];
                    clearSpikeTimer = nil;
                }
            }
        }
    }
}


@end

