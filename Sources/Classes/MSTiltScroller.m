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

#define kMinScrollAngleV		10.0f
#define kMaxScrollAngleV		70.0f

#define kMinScrollBufferV	5.0f
#define kMaxScrollBufferV	0.0f

#define kMinScrollSpeedV		1.0f
#define kMaxScrollSpeedV		8.0f


#define kMinScrollAngleH		10.0f
#define kMaxScrollAngleH		50.0f

#define kMinScrollBufferH	2.0f
#define kMaxScrollBufferH	0.0f

#define kMinScrollSpeedH		1.0f
#define kMaxScrollSpeedH		8.0f


#define kScrollUpDirection	-1
#define kScrollDownDirection 1

//extern BOOL gTouchDownOnWebView;

@implementation MSTiltScroller

@synthesize webView, scrollView;
@synthesize delegate;
@synthesize enabled;
@synthesize initialAngleV;
@synthesize initialAngleH;
@synthesize initialAngleY;
@synthesize initialAngleZ;
@synthesize bezelView;

@synthesize lastSpeedV;
@synthesize lastSpeedH;
@synthesize directionModifierH, directionModifierV;

- (id)init {
    
	self = [super init];
	
	directionModifierH = 1;
	directionModifierV = 1;    
	
	
	
	
	
	initialAngleV = -100;
	initialAngleH = -100;    
	initialAngleY = -100;
	initialAngleZ = -100;
	lastSpeedV = 0;
	enabled = true;
	
	oldOrientation = [[UIDevice currentDevice] orientation];
	xMultiplier = 1;
	if (oldOrientation == UIDeviceOrientationLandscapeRight) xMultiplier = -1;
    
	return self;
	
}

- (id)initWithScrollView:(UIScrollView *)sv {
	
    self = [super init];
	self.scrollView = sv; 
	
	
	
	
	directionModifierH = 1;
	directionModifierV = 1;    
	
	initialAngleV = -100;
	initialAngleH = -100;    
	initialAngleY = -100;
	initialAngleZ = -100;
	lastSpeedV = 0;
	enabled = false;
	
	oldOrientation = [[UIDevice currentDevice] orientation];
	xMultiplier = 1;
	if (oldOrientation == UIDeviceOrientationLandscapeRight) xMultiplier = -1;
    
	return self;
	
    
}

- (id)initWithWebView:(UIWebView *)wv {
	self = [super init];
	self.webView = wv; 
    
	
	
	directionModifierH = 1;
	directionModifierV = 1;    
    
    
	initialAngleV = -100;
	initialAngleH = -100;    
	initialAngleY = -100;
	initialAngleZ = -100;
	lastSpeedV = 0;
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

- (void)scrollScrollViewY:(int)distanceY X:(int)distanceX {
    if ([scrollView isDragging] || [scrollView isZooming]) return;
    
    float newY = scrollView.contentOffset.y + distanceY;
    float newX = scrollView.contentOffset.x + (float)distanceX;
    
    if (newY > (scrollView.contentSize.height-scrollView.frame.size.height)) newY = scrollView.contentSize.height-scrollView.frame.size.height;
    if (newY < 0) newY = 0;
    
    if (newX > (scrollView.contentSize.width-scrollView.frame.size.width)) newX = scrollView.contentSize.width-scrollView.frame.size.width;
    if (newX < 0) newX = 0;
    
    //    if (newY <= scrollView.contentSize.height-scrollView.frame.size.height && newY >= 0) [scrollView scrollRectToVisible:CGRectMake(scrollView.contentOffset.x, newY, scrollView.frame.size.width, scrollView.frame.size.height) animated:NO];    
    [scrollView scrollRectToVisible:CGRectMake(newX, newY, scrollView.frame.size.width, scrollView.frame.size.height) animated:NO];        
}

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
        //		initialAngleV = (acceleration.z - acceleration.y - acceleration.x*xMultiplier);
		initialAngleV = (acceleration.z - acceleration.y);        
        initialAngleH = -acceleration.x*xMultiplier;
		return;
	}
    
    //	float acc = (acceleration.z - acceleration.y - acceleration.x*xMultiplier);
	float accV = (acceleration.z - acceleration.y);    
	float accH = -acceleration.x*xMultiplier;        
    
	float currentAngleV;
    float currentAngleH;
    
	float directionV = 1;
	float directionH = 1;    
    
	if (initialAngleV < accV) {
		currentAngleV = accV - initialAngleV;
		directionV = kScrollDownDirection*directionModifierV;
	} else {
        
		currentAngleV = initialAngleV - accV;//+.05;
		directionV = kScrollUpDirection*directionModifierV;
	}
    
    if (initialAngleH < accH) {
		currentAngleH = accH - initialAngleH;
		directionH = kScrollUpDirection*directionModifierH;
	} else {
        
		currentAngleH = initialAngleH - accH;//+.05;
		directionH = kScrollDownDirection*directionModifierH;
	}
    
    
    
	currentAngleV = currentAngleV * 90.0f;
	currentAngleH = currentAngleH * 90.0f;    
    
	float newScrollSpeedV = [self calculateSpeedV:currentAngleV];
	float newScrollSpeedH = [self calculateSpeedH:currentAngleH];    
    
	if (newScrollSpeedV > lastSpeedV) {
		float tempSpeed = [self calculateSpeedV:((float)(currentAngleV-3.0f))];
		if (tempSpeed != newScrollSpeedV) newScrollSpeedV = lastSpeedV;
	}
	
	if (newScrollSpeedV < lastSpeedV) {
		float tempSpeed = [self calculateSpeedV:((float)(currentAngleV+3.0f))];
		if (tempSpeed != newScrollSpeedV) newScrollSpeedV = lastSpeedV;
        
	}
    
	
    
	lastSpeedV = newScrollSpeedV;
    
    
	if (newScrollSpeedH > lastSpeedH) {
		float tempSpeed = [self calculateSpeedH:((float)(currentAngleH-3.0f))];
		if (tempSpeed != newScrollSpeedH) newScrollSpeedH = lastSpeedH;
	}
	
	if (newScrollSpeedH < lastSpeedH) {
		float tempSpeed = [self calculateSpeedH:((float)(currentAngleH+3.0f))];
		if (tempSpeed != newScrollSpeedH) newScrollSpeedH = lastSpeedH;
        
	}
    
	
    
	lastSpeedH = newScrollSpeedH;
    
	if (newScrollSpeedV == 0 && newScrollSpeedH == 0) {
        
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
    

    if (scrollView) [self scrollScrollViewY:directionV*newScrollSpeedV X:directionH*newScrollSpeedH];

    
	
    
	
}

- (void)updateScrollBar {
    
	
    
	
	NSNotification* note = [NSNotification notificationWithName:@"BCWebViewScrolled" object:0 userInfo:0];
	[[NSNotificationCenter defaultCenter] performSelector:@selector(postNotification:) withObject:note];	
	
    
}





- (float)calculateSpeedH:(float)angle {
	

	if (angle < kMinScrollAngleH) return 0;
	
	if (angle > kMaxScrollAngleH) return kMaxScrollSpeedH;
	
	if ((angle-kMinScrollBufferH) < kMinScrollAngleH) return kMinScrollSpeedH;
    
	if ((angle-kMaxScrollBufferH) > kMaxScrollAngleH) return kMaxScrollSpeedH;
    
	float angleRange = kMaxScrollAngleH - kMinScrollAngleH - kMinScrollBufferH - kMaxScrollBufferH;
	float anglePercent2 = (angle - kMinScrollAngleH - kMinScrollBufferH)/ angleRange;

	return (float)((int)((kMaxScrollSpeedH - kMinScrollSpeedH) * anglePercent2 + kMinScrollSpeedH));		
	
}



- (float)calculateSpeedV:(float)angle {
	
    
	if (angle < kMinScrollAngleV) return 0;
	
	if (angle > kMaxScrollAngleV) return kMaxScrollSpeedV;
	
	if ((angle-kMinScrollBufferV) < kMinScrollAngleV) return kMinScrollSpeedV;
    
	if ((angle-kMaxScrollBufferV) > kMaxScrollAngleV) return kMaxScrollSpeedV;
    
	float angleRange = kMaxScrollAngleV - kMinScrollAngleV - kMinScrollBufferV - kMaxScrollBufferV;
	float anglePercent2 = (angle - kMinScrollAngleV - kMinScrollBufferV)/ angleRange;

	return (float)((int)((kMaxScrollSpeedV - kMinScrollSpeedV) * anglePercent2 + kMinScrollSpeedV));		
	
}

- (void)dealloc {
	
    //	[bezelView release];
    [super dealloc];
}


@end
