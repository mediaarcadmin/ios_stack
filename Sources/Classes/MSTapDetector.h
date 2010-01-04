//
//  MSTapDetector.h
//  TapTurningDemo
//
//  Created by David Keay on 1/3/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kHistorySize 150



@interface MSTapDetector : NSObject
{
    NSUInteger nextIndex;
    UIAccelerationValue acceleration[3];
    
    // Two dimensional array of acceleration data.
    UIAccelerationValue history[kHistorySize][3];
    
    NSTimeInterval timeOfFirstSpike;
    NSTimeInterval timeOfLastPageTurn;    
    int numSpikes;
    int signOfFirstSpike;
    
    NSTimer *clearSpikeTimer;
    
    UILabel *feedbackLabel;
}



@property NSTimeInterval timeOfFirstSpike;
@property NSTimeInterval timeOfLastPageTurn;
@property int numSpikes;
@property int signOfFirstSpike;

@property (nonatomic, assign) UILabel *feedbackLabel;


- (void)updateHistoryWithX:(float)x Y:(float)y Z:(float)z;
- (void)clearSpikeHistory;

@end
