//
//  BlioBookViewControllerProgressPieButton.m
//  BlioApp
//
//  Created by James Montgomerie on 21/04/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioBookViewControllerProgressPieButton.h"
#import <QuartzCore/QuartzCore.h>

@implementation BlioBookViewControllerProgressPieButton

@synthesize progress, tintColor, toggled;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
        self.progress = 0.0f;
        self.toggled = NO;
        self.backgroundColor = [UIColor clearColor];
        self.tintColor = [UIColor blackColor];
        
        [self addTarget:self action:@selector(highlightOn) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(highlightOff) forControlEvents:UIControlEventTouchUpInside];
        [self addTarget:self action:@selector(highlightOff) forControlEvents:UIControlEventTouchUpOutside];
        [self addTarget:self action:@selector(highlightOff) forControlEvents:UIControlEventTouchCancel];
    }
    return self;
}

- (void)dealloc {
    self.tintColor = nil;
    [super dealloc];
}

- (void)highlightOn {
    [self setHighlighted:YES];
    [self setNeedsDisplay];
}

- (void)highlightOff {
    [self setHighlighted:NO];
    [self setNeedsDisplay];
}

- (void)setProgress:(CGFloat)newFloat {
    progress = newFloat;
    [self setNeedsDisplay];
}

- (void)setToggled:(BOOL)newToggle {
    toggled = newToggle;
    [self setNeedsDisplay];
}

- (void)setTintColor:(UIColor *)newTint {
    [newTint retain];
    [tintColor release];
    tintColor = newTint;
    [self setNeedsDisplay];
}

void addRoundedRectToPath(CGContextRef c, CGFloat radius, CGRect rect) {
    CGContextSaveGState(c);
    
    if (radius > rect.size.width/2.0)
        radius = rect.size.width/2.0;
    if (radius > rect.size.height/2.0)
        radius = rect.size.height/2.0;    
    
    CGFloat minx = CGRectGetMinX(rect);
    CGFloat midx = CGRectGetMidX(rect);
    CGFloat maxx = CGRectGetMaxX(rect);
    CGFloat miny = CGRectGetMinY(rect);
    CGFloat midy = CGRectGetMidY(rect);
    CGFloat maxy = CGRectGetMaxY(rect);
    CGContextMoveToPoint(c, minx, midy);
    CGContextAddArcToPoint(c, minx, miny, midx, miny, radius);
    CGContextAddArcToPoint(c, maxx, miny, maxx, midy, radius);
    CGContextAddArcToPoint(c, maxx, maxy, midx, maxy, radius);
    CGContextAddArcToPoint(c, minx, maxy, minx, midy, radius);
    
    CGContextClosePath(c); 
    CGContextRestoreGState(c); 
}

void drawGlossGradient(CGContextRef c, CGRect rect) {
    CGGradientRef glossGradient;
    CGColorSpaceRef rgbColorspace;
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    CGFloat components[8] = { 1.0, 1.0, 1.0, 0.380,  // Start color
        1.0, 1.0, 1.0, 0.188 }; // End color
    
    rgbColorspace = CGColorSpaceCreateDeviceRGB();
    glossGradient = CGGradientCreateWithColorComponents(rgbColorspace, components, locations, num_locations);
    
    CGPoint topCenter = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
    CGPoint midCenter = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    CGContextDrawLinearGradient(c, glossGradient, topCenter, midCenter, 0);    
    CGGradientRelease(glossGradient);
    CGColorSpaceRelease(rgbColorspace);
}

void addOvalToPath(CGContextRef c, CGPoint center, float a, float b, 
                   float start_angle, float arc_angle, int pie) { 
    float CGstart_angle = 90.0 - start_angle; 
    CGContextSaveGState(c); 
    CGContextTranslateCTM(c, center.x, center.y); 
    CGContextScaleCTM(c, a, b); 
    if (pie) { 
        CGContextMoveToPoint(c, 0, 0); 
    } else { 
        CGContextMoveToPoint(c, cos(CGstart_angle * M_PI / 180), 
                             sin(CGstart_angle * M_PI / 180)); 
    } 
    CGContextAddArc(c, 0, 0, 1, 
                    CGstart_angle * M_PI / 180, 
                    (CGstart_angle - arc_angle) * M_PI / 180, 
                    arc_angle>0 ? 1 : 0); 
    if (pie) { 
        CGContextClosePath(c); 
    } 
    CGContextRestoreGState(c); 
} 

void fillOval(CGContextRef c, CGRect rect, float start_angle, float arc_angle) { 
    float a, b; 
    CGPoint center; 
    CGContextBeginPath(c); 
    center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect)); 
    a = CGRectGetWidth(rect) / 2; 
    b = CGRectGetHeight(rect) / 2; 
    addOvalToPath(c, center, a, b, start_angle, arc_angle, 1); 
    CGContextClosePath(c); 
    CGContextFillPath(c); 
}

- (void)drawRect:(CGRect)rect {    
    // Drawing code
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(ctx, 0.0, CGRectGetMaxY(rect));
    CGContextScaleCTM(ctx, 1.0, -1.0);
    
    CGFloat yButtonPadding = rect.size.height - 19;
    if (yButtonPadding > 7) yButtonPadding = 7;
    //    
    //CGFloat xButtonPadding = yButtonPadding;
    //CGFloat yButtonPadding = 7.0f;
    CGFloat xButtonPadding = 7.0f;
    CGFloat wedgePadding = 2.0f;
    CGRect inRect = CGRectInset(rect, xButtonPadding, yButtonPadding);
    CGFloat insetX, insetY;
    CGFloat width = inRect.size.width;
    CGFloat height = inRect.size.height;
    
    if (width > height) {
        insetX = (width - height); // Right aligned
        insetY = 0;
        width = width - insetX;
    } else {
        insetX = 0;
        insetY = (height - width)/2.0f;
        height = height - 2 * insetY;
    }
    
    //CGRect outerSquare = CGRectIntegral(CGRectMake(inRect.origin.x + insetX, inRect.origin.y + insetY + 1, width, height));
    CGRect outerFrame = CGRectIntegral(CGRectMake(inRect.origin.x + insetX, inRect.origin.y + insetY, width, height));
    
    CGRect innerSquare = CGRectInset(outerFrame, wedgePadding, wedgePadding);
    CGRect buttonSquare = CGRectInset(outerFrame, -xButtonPadding, -yButtonPadding);
    //buttonSquare.origin.y -= 1;
    backgroundFrame = UIEdgeInsetsInsetRect(buttonSquare, UIEdgeInsetsMake(1, 0, 0, 0));
    
    CGContextClipToRect(ctx, buttonSquare);
    
    
    if ([self isHighlighted] || toggled) {
        CGContextSetShadowWithColor(ctx, CGSizeMake(0,-1), 0, [UIColor colorWithWhite:0.5f alpha:0.25f].CGColor);
    } else {
        CGContextSetShadowWithColor(ctx, CGSizeMake(0,-1), 0, [UIColor colorWithWhite:1.0f alpha:0.25f].CGColor);
    }
    
    CGContextBeginTransparencyLayer(ctx, NULL);
    addRoundedRectToPath(ctx, 6.0f, backgroundFrame);
    CGContextClip(ctx);
    
    CGContextSetFillColorWithColor(ctx, tintColor.CGColor);
    CGContextFillRect(ctx, backgroundFrame);
    drawGlossGradient(ctx, backgroundFrame);
    
    CGContextSetShadowWithColor(ctx, CGSizeMake(0,-0.5f), 0.5f, [UIColor colorWithWhite:0.0f alpha:0.75f].CGColor);
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:0.0f alpha:0.75f].CGColor);
    CGContextSetLineWidth(ctx, 1.0f);
    addRoundedRectToPath(ctx, 6.0f, backgroundFrame);
    CGContextStrokePath(ctx);
    
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:1.0f alpha:1.0f].CGColor);
    CGContextSetLineWidth(ctx, 2.0f);
    
    CGContextSaveGState(ctx);
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, 1.0f), 0.0f, [UIColor colorWithWhite:0.0f alpha:0.5f].CGColor);
    CGContextStrokeEllipseInRect(ctx, outerFrame);
    CGContextRestoreGState(ctx);
    
    if (progress) {
        CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite:1.0f alpha:1.0f].CGColor);
        fillOval(ctx, innerSquare, 0, progress*360);
    }
    
    if ([self isHighlighted] || toggled) {
        CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite:0.0f alpha:0.25f].CGColor);
        CGContextFillRect(ctx, backgroundFrame);
    }
    
    CGContextEndTransparencyLayer(ctx);
}

- (BOOL)isAccessibilityElement {
    return YES;
}

- (CGRect)accessibilityFrame {
    return [self.window.layer convertRect:backgroundFrame fromLayer:self.layer];
}

- (UIAccessibilityTraits)accessibilityTraits {
    UIAccessibilityTraits traits = UIAccessibilityTraitButton;
    if ([self isHighlighted] || toggled)
        traits |= UIAccessibilityTraitSelected;
    
    return traits;
}

- (NSString *)accessibilityLabel {
    return  NSLocalizedString(@"Book position", @"Accessibility label for Book View Controller Progress button");
}

- (NSString *)accessibilityValue {
    return  [NSString stringWithFormat:NSLocalizedString(@"%.0f%%", @"Accessibility label for Book View Controller Progress value"), self.progress * 100];
}

- (NSString *)accessibilityHint {
    return  NSLocalizedString(@"Toggles book position slider.", @"Accessibility label for Book View Controller Progress hint");
}

@end