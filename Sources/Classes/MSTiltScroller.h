//
//  BCTiltScroller.h
//  scroll
//
//  Created by David Keay on 9/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MSTiltScroller : NSObject <UIAccelerometerDelegate> {
	UIWebView *webView;
	UIScrollView *scrollView;
    
	bool enabled;
	
	float initialAngleY;
	float initialAngleZ;
    
	float initialAngleV;
	float initialAngleH;    
    
	int xMultiplier;
    
	
	UIImageView *bezelView;
	
	int lastSpeedV;
	int lastSpeedH;    
	
	NSTimer* scrollbarUpdateTimer;
	
	UIDeviceOrientation oldOrientation;
	
	id delegate;
    
    int directionModifierH;
    int directionModifierV;    
}



@property (nonatomic, retain) UIImageView *bezelView;
@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) UIScrollView *scrollView;


@property (nonatomic) bool enabled;
@property (nonatomic) float initialAngleV;
@property (nonatomic) float initialAngleH;
@property (nonatomic) float initialAngleY;
@property (nonatomic) float initialAngleZ;


@property (nonatomic) int lastSpeedV;
@property (nonatomic) int lastSpeedH;

@property (nonatomic, assign) id delegate;

@property (nonatomic) int directionModifierH;
@property (nonatomic) int directionModifierV;

- (id)initWithWebView:(UIWebView *)wv;
- (id)initWithScrollView:(UIScrollView *)sv;


- (float)calculateSpeedV:(float)angle;
- (float)calculateSpeedH:(float)angle;
- (void)stop:(bool)showBezel;
- (void)start:(bool)showBezel;
- (bool)toggleScroller:(bool)showBezel;
- (void)displayBezelImage:(NSString *)path;
- (void)resetAngle;

@end
