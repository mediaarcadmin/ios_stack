//
//  BlioRoundedRectActivityView.m
//  BlioApp
//
//  Created by Don Shin on 9/21/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import "BlioRoundedRectActivityView.h"

static CGFloat BlioActivityIndicatorDiameter = 24.0f;


@implementation BlioRoundedRectActivityView

@synthesize activityIndicator,strokeColor,fillColor;

-(id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		[super setOpaque:NO];
		self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((self.frame.size.width-BlioActivityIndicatorDiameter)/2, (self.frame.size.height-BlioActivityIndicatorDiameter)/2, BlioActivityIndicatorDiameter, BlioActivityIndicatorDiameter)] autorelease];	
		[activityIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
		[super setBackgroundColor:[UIColor clearColor]];
        strokeColor = [[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.5f] retain];
        fillColor = [[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.5f] retain];
		self.alpha = 0;
		[self addSubview:activityIndicator];
	}
	return self;
}
- (void)dealloc {
	self.activityIndicator = nil;
	[super setBackgroundColor:nil];
	[strokeColor release];
	[fillColor release];
	[super dealloc];
}
-(void)startAnimating {
	[self.activityIndicator startAnimating];
	[UIView beginAnimations:@"startAnimating" context:nil];
	[UIView setAnimationDuration:0.5f];
	self.alpha = 1.0f;
	[UIView setAnimationDidStopSelector:@selector(downloadButtonAnimationFinished:finished:context:)];
	[UIView commitAnimations];
	
}
-(void)stopAnimating {
	[UIView beginAnimations:@"stopAnimating" context:nil];
	[UIView setAnimationDuration:0.5f];
	[UIView setAnimationDelegate:self];
	self.alpha = 0;
	[UIView setAnimationDidStopSelector:@selector(stopAnimatingFinished:finished:context:)];
	[UIView commitAnimations];
	
}
- (void)stopAnimatingFinished:(NSString *)animationID finished:(BOOL)finished context:(void *)context {
	[self.activityIndicator stopAnimating];
}
- (void)setBackgroundColor:(UIColor *)newBGColor
{
	NSLog(@"WARNING: background color attempted to be set!");
}
- (void)setOpaque:(BOOL)newIsOpaque
{
	NSLog(@"WARNING: opacity attempted to be set!");
}
- (void)drawRect:(CGRect)rect {
	
	CGFloat strokeWidth = 1;
	CGFloat cornerRadius = 10;
	
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, strokeWidth);
    CGContextSetStrokeColorWithColor(context, self.strokeColor.CGColor);
    CGContextSetFillColorWithColor(context, self.fillColor.CGColor);
	
    CGRect rrect = self.bounds;
	
    CGFloat radius = cornerRadius;
    CGFloat width = CGRectGetWidth(rrect);
    CGFloat height = CGRectGetHeight(rrect);
	
    // Make sure corner radius isn't larger than half the shorter side
    if (radius > width/2.0)
        radius = width/2.0;
    if (radius > height/2.0)
        radius = height/2.0;    
    CGFloat minx = CGRectGetMinX(rrect);
    CGFloat midx = CGRectGetMidX(rrect);
    CGFloat maxx = CGRectGetMaxX(rrect);
    CGFloat miny = CGRectGetMinY(rrect);
    CGFloat midy = CGRectGetMidY(rrect);
    CGFloat maxy = CGRectGetMaxY(rrect);
    CGContextMoveToPoint(context, minx, midy);
    CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
    CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
    CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
    CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFillStroke);
}



@end
