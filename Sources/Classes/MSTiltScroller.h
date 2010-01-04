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
	float initialAngle;

	int xMultiplier;

	
	UIImageView *bezelView;
	
	int lastSpeed;
	
	NSTimer* scrollbarUpdateTimer;
	
	UIDeviceOrientation oldOrientation;
	
	id delegate;

}



@property (nonatomic, retain) UIImageView *bezelView;
@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) UIScrollView *scrollView;


@property (nonatomic) bool enabled;
@property (nonatomic) float initialAngle;
@property (nonatomic) float initialAngleY;
@property (nonatomic) float initialAngleZ;


@property (nonatomic) int lastSpeed;

@property (nonatomic, assign) id delegate;

- (id)initWithWebView:(UIWebView *)wv;
- (id)initWithScrollView:(UIScrollView *)sv;


- (float)calculateSpeed:(float)angle;
- (void)stop:(bool)showBezel;
- (void)start:(bool)showBezel;
- (bool)toggleScroller:(bool)showBezel;
- (void)displayBezelImage:(NSString *)path;

@end
