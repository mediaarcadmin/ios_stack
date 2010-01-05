//
//  BCTiltScroller.m
//  scroll
//
//  Created by David Keay on 9/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MSTiltScroller.h"

#define kAccelerometerFrequency     40


/*
 The phone will start scrolling when you are at more than kMinScrollAngle away from when you enabled the feature, scrolling at kMinScrollSpeed between the minScrollAngle and the minScrollAngle + minScrollBuffer.
 Between (minScrollAngle+minScrollBuffer) and (maxScrollAngle-maxScrollBuffer), it will increase the scroll rate linearly between minScrollSpeed and maxScrollSpeed.
 For angles greater than maxScrollAngle+maxScrollBuffer, the phone will scroll at the maximum scroll speed
 
 */

#define kMinScrollAngle		10.0f
#define kMaxScrollAngle		70.0f

#define kMinScrollBuffer	5.0f
#define kMaxScrollBuffer	0.0f

#define kMinScrollSpeed		1.0f
#define kMaxScrollSpeed		8.0f

#define kScrollUpDirection	-1
#define kScrollDownDirection 1

//extern BOOL gTouchDownOnWebView;

@implementation MSTiltScroller

@synthesize webView, scrollView;
@synthesize delegate;
@synthesize enabled;
@synthesize initialAngle;
@synthesize initialAngleY;
@synthesize initialAngleZ;
@synthesize bezelView;

@synthesize lastSpeed;



- (id)init {
    
	self = [super init];
	
	
	
	
	
	
	
	initialAngle = -100;
	initialAngleY = -100;
	initialAngleZ = -100;
	lastSpeed = 0;
	enabled = true;
	
	oldOrientation = [[UIDevice currentDevice] orientation];
	xMultiplier = 1;
	if (oldOrientation == UIDeviceOrientationLandscapeRight) xMultiplier = -1;
		
	return self;
	
}

- (id)initWithScrollView:(UIScrollView *)sv {
	
    self = [super init];
	self.scrollView = sv; 
	
	
	
	
	
	
	initialAngle = -100;
	initialAngleY = -100;
	initialAngleZ = -100;
	lastSpeed = 0;
	enabled = false;
	
	oldOrientation = [[UIDevice currentDevice] orientation];
	xMultiplier = 1;
	if (oldOrientation == UIDeviceOrientationLandscapeRight) xMultiplier = -1;
		
	return self;
	

}

- (id)initWithWebView:(UIWebView *)wv {
	self = [super init];
	self.webView = wv; 

	
	
	
		
		
	initialAngle = -100;
	initialAngleY = -100;
	initialAngleZ = -100;
	lastSpeed = 0;
	enabled = false;

	oldOrientation = [[UIDevice currentDevice] orientation];
	xMultiplier = 1;
	if (oldOrientation == UIDeviceOrientationLandscapeRight) xMultiplier = -1;
	
	return self;
	
}



-(void)autoRotateBezel:(NSNotification*)note
{

	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];

	if ((UIDeviceOrientationIsPortrait(oldOrientation) && UIDeviceOrientationIsLandscape(orientation)) || (UIDeviceOrientationIsPortrait(orientation) && UIDeviceOrientationIsLandscape(oldOrientation))) {
		initialAngleY = -100;
		if (enabled) {
			[self stop:NO];

			[self performSelector:@selector(start) withObject:self afterDelay:1];
		}
		
	}
	
	if (orientation == UIDeviceOrientationLandscapeLeft) xMultiplier = 1;
		else xMultiplier = -1;

		
		[UIView beginAnimations:@"rotating bezel" context:self];
		
		
		if (orientation == UIDeviceOrientationLandscapeLeft) {
			[bezelView setFrame:CGRectMake(80, 160, 160, 160)];
			bezelView.transform = CGAffineTransformMakeRotation(M_PI/2);
		}
		if (orientation == UIDeviceOrientationLandscapeRight) {
			[bezelView setFrame:CGRectMake(80, 160, 160, 160)];
			bezelView.transform = CGAffineTransformMakeRotation(-M_PI/2);
		}
		if (orientation == UIDeviceOrientationPortrait || orientation == UIDeviceOrientationPortraitUpsideDown) {
			[bezelView setFrame:CGRectMake(80, 178, 160, 160)];
			bezelView.transform = CGAffineTransformMakeRotation(0);
		}
		[UIView commitAnimations];

	oldOrientation = orientation;
}


- (bool)toggleScroller:(bool)showBezel {
	if (enabled) {
		[self stop:showBezel];
		return false;
	}
	else {
		[self start:showBezel]; 
		return true;
	}
}

- (void)stop:(bool)showBezel {

	if (scrollbarUpdateTimer)
	{
		[scrollbarUpdateTimer invalidate];
		scrollbarUpdateTimer = 0;
	}
	if (enabled == false) return;
	initialAngleY = -100;
	initialAngleZ = -100;
	enabled = false;


	[UIApplication sharedApplication].idleTimerDisabled = NO;	
}

- (void)start { 
	[self start:NO];
}

- (void)start:(bool)showBezel {

	if (enabled == true) return;
	enabled = true;
}


- (void) fadeOutBezel {

	[UIView beginAnimations:@"hideBezel" context:nil];

	[UIView setAnimationDelay:1];
	[UIView setAnimationDuration:1];
	[UIView setAnimationDelegate:self];
	
	[bezelView setAlpha:0];
	
	[UIView setAnimationDidStopSelector:@selector(bezelFadeDidStop:finished:context:)];	
	[UIView commitAnimations];
	
	
}

- (void) displayBezelImage:(NSString *)imageName {

	[bezelView removeFromSuperview];
	[bezelView setImage:[UIImage imageNamed:imageName]];
	[bezelView setAlpha:1];
	UIWindow *w = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
	[w addSubview:bezelView];
	[self fadeOutBezel];
	
	
}


- (void) bezelFadeDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	if ([finished intValue] == 1) [bezelView removeFromSuperview];

}

/*- (void)scrollBlioView:(int)distance {
    
    UIScrollView *blioScrollView = [blioView getCurrentScrollView];
    float newY = blioScrollView.contentOffset.y + distance;
    if (newY <= blioScrollView.contentSize.height-blioScrollView.frame.size.height && newY >= 0) [blioScrollView scrollRectToVisible:CGRectMake(blioScrollView.contentOffset.x, newY, blioScrollView.frame.size.width, blioScrollView.frame.size.height) animated:NO];
    
}*/


- (void)scrollScrollView:(int)distance {
    if ([scrollView isDragging] || [scrollView isZooming]) return;

    float newY = scrollView.contentOffset.y + distance;
    if (newY <= scrollView.contentSize.height-scrollView.frame.size.height && newY >= 0) [scrollView scrollRectToVisible:CGRectMake(scrollView.contentOffset.x, newY, scrollView.frame.size.width, scrollView.frame.size.height) animated:NO];

}

- (void)scrollWebView:(int)distance {


	
	int currentScrollY = [[webView stringByEvaluatingJavaScriptFromString:@"window.pageYOffset;"] intValue];
	int currentScrollX = [[webView stringByEvaluatingJavaScriptFromString:@"window.pageXOffset;"] intValue];



	[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"scroll(%d, %d)", (int)currentScrollX, (int)(currentScrollY+distance)]];		
 
}

- (void)resetAngle {

 	initialAngleY = -100;
	initialAngleZ = -100;   
}

// UIAccelerometerDelegate method, called when the device accelerates.
- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {

    if (!enabled) return;

/*	if (!scrollbarUpdateTimer && lastSpeed != 0) {

		[UIApplication sharedApplication].idleTimerDisabled = YES;
		[UIApplication sharedApplication].idleTimerDisabled = NO;
		scrollbarUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:.2 target:self selector:@selector(updateScrollBar) userInfo:0 repeats:YES];	
	}*/
//	float acc = acceleration.z-acceleration.x;
	if (initialAngleY == -100) {
		initialAngleY = acceleration.y;
		initialAngleZ = acceleration.z;
		initialAngle = (acceleration.z - acceleration.y - acceleration.x*xMultiplier);
		return;
	}

	float acc = (acceleration.z - acceleration.y - acceleration.x*xMultiplier);

	float currentAngle;
	float direction = 1;

	if (initialAngle < acc) {
		currentAngle = acc - initialAngle;
		direction = kScrollUpDirection;
	} else {

		currentAngle = initialAngle - acc;//+.05;
		direction = kScrollDownDirection;
	}



	currentAngle = currentAngle * 90.0f;

	float newScrollSpeed = [self calculateSpeed:currentAngle];

	if (newScrollSpeed > lastSpeed) {
		float tempSpeed = [self calculateSpeed:((float)(currentAngle-3.0f))];
		if (tempSpeed != newScrollSpeed) newScrollSpeed = lastSpeed;
	}
	
	if (newScrollSpeed < lastSpeed) {
		float tempSpeed = [self calculateSpeed:((float)(currentAngle+3.0f))];
		if (tempSpeed != newScrollSpeed) newScrollSpeed = lastSpeed;

	}

	

	lastSpeed = newScrollSpeed;
	if (newScrollSpeed == 0) {

		if ([UIApplication sharedApplication].idleTimerDisabled) {

			[UIApplication sharedApplication].idleTimerDisabled = NO;
		}
		if (scrollbarUpdateTimer)
		{
			
			[scrollbarUpdateTimer invalidate];
			scrollbarUpdateTimer = 0;
		}
		return;
	}
    
    if (webView) [self scrollWebView:direction*newScrollSpeed];
	else if (scrollView) [self scrollScrollView:direction*newScrollSpeed];
//    else if (blioView) [self scrollBlioView:direction*newScrollSpeed];

	

	
}

- (void)updateScrollBar {

	

	
	NSNotification* note = [NSNotification notificationWithName:@"BCWebViewScrolled" object:0 userInfo:0];
	[[NSNotificationCenter defaultCenter] performSelector:@selector(postNotification:) withObject:note];	
	

}



- (float)calculateSpeed:(float)angle {
	

	if (angle < kMinScrollAngle) return 0;
	
	if (angle > kMaxScrollAngle) return kMaxScrollSpeed;
	
	if ((angle-kMinScrollBuffer) < kMinScrollAngle) return kMinScrollSpeed;

	if ((angle-kMaxScrollBuffer) > kMaxScrollAngle) return kMaxScrollSpeed;

	float angleRange = kMaxScrollAngle - kMinScrollAngle - kMinScrollBuffer - kMaxScrollBuffer;
	float anglePercent2 = (angle - kMinScrollAngle - kMinScrollBuffer)/ angleRange;

	return (float)((int)((kMaxScrollSpeed - kMinScrollSpeed) * anglePercent2 + kMinScrollSpeed));		
	
}

- (void)dealloc {
	
//	[bezelView release];
    [super dealloc];
}


@end
