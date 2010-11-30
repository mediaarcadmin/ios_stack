//
//  BlioNotesView.m
//  BlioApp
//
//  Created by matt on 31/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "BlioNotesView.h"
#import "BlioUIImageAdditions.h"

static const CGFloat kBlioNotesViewPhoneShadow = 16;
static const CGFloat kBlioNotesViewPadBorder = 6;
static const CGFloat kBlioNotesViewNoteHeight = 200;
static const CGFloat kBlioNotesViewNotePadWidth = 320;
static const CGFloat kBlioNotesViewNotePadBottomInset = 264;

static const CGFloat kBlioNotesViewNotePhoneYInset = -40;
static const CGFloat kBlioNotesViewNotePadYInset = -20;
static const CGFloat kBlioNotesViewToolbarHeight = 44;
static const CGFloat kBlioNotesViewToolbarLabelWidth = 140;
static const CGFloat kBlioNotesViewTextXInset = 8;
static const CGFloat kBlioNotesViewTextTopInset = 8;
static const CGFloat kBlioNotesViewTextBottomInset = 24;

static NSString * const BlioNotesViewShowFromTopAnimation = @"BlioNotesViewShowFromTopAnimation";
static NSString * const BlioNotesViewExitToTopAnimation = @"BlioNotesViewExitToTopAnimation";

@interface BlioNotesView()

@property (nonatomic, assign) UIView *showInView;

@end

@implementation BlioNotesView

@synthesize page, textView, delegate, note, range, toolbarLabel, showInView, noteSaved;

- (void)dealloc {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    self.page = nil;
    self.textView = nil;
    self.toolbarLabel = nil;
    self.delegate = nil;
    self.note = nil;
    self.range = nil;
    self.showInView = nil;
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame {
    return [self initWithRange:nil note:nil];
}

- (id)initWithRange:(BlioBookmarkRange *)aRange note:(NSManagedObject *)aNote {
    if (nil == aRange) return nil;
    
    if ((self = [super initWithFrame:CGRectZero])) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        self.page = [[NSNumber numberWithInteger:[[aRange startPoint] layoutPage]] stringValue];
        self.note = aNote;
		self.noteSaved = NO;
        self.range = aRange;
        // Setting this forces layoutSubviews to be called on a rotation
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.autoresizesSubviews = YES;
        
        // Ensures that the note shows above it's sibling views
        self.layer.zPosition = 1000;
        
        bottomInset = kBlioNotesViewNotePadBottomInset;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
        }
    }
    return self;
}

- (void)showInView:(UIView *)view {
    [self showInView:view animated:YES];
}

- (void)layoutNote {
    CGRect newFrame;
    CGRect toolbarFrame;
    UIView *container = self.showInView;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        newFrame = CGRectMake(0, 
                                 (container.bounds.size.height - (2 * kBlioNotesViewPhoneShadow + kBlioNotesViewNoteHeight))/2.0f + kBlioNotesViewNotePhoneYInset,
                                 container.bounds.size.width,
                                 2 * kBlioNotesViewPhoneShadow + kBlioNotesViewNoteHeight);
        toolbarFrame = CGRectMake((newFrame.size.width - kBlioNotesViewToolbarLabelWidth)/2.0f, kBlioNotesViewPhoneShadow, kBlioNotesViewToolbarLabelWidth, kBlioNotesViewToolbarHeight);

    } else {
        newFrame = CGRectMake((container.bounds.size.width - kBlioNotesViewNotePadWidth) / 2, 
                              container.bounds.size.height - (bottomInset + kBlioNotesViewNoteHeight) - kBlioNotesViewNotePadYInset,
                              kBlioNotesViewNotePadWidth,
                              kBlioNotesViewNoteHeight);
        toolbarFrame = CGRectMake((newFrame.size.width - kBlioNotesViewToolbarLabelWidth)/2.0f, kBlioNotesViewPadBorder, kBlioNotesViewToolbarLabelWidth, kBlioNotesViewToolbarHeight);
    }
    
    self.frame = newFrame;

    self.toolbarLabel.frame = toolbarFrame;
    //[self setNeedsDisplay];
}

- (void)showInView:(UIView *)view animated:(BOOL)animated {
    [self removeFromSuperview];
    self.showInView = view;
    // Insert below the view so that it gets the rotation resizing
    // The layer zPosition will take care of showing it above it's sibling
    [[self.showInView superview] insertSubview:self belowSubview:self.showInView];
    [self.showInView setUserInteractionEnabled:NO];
    
    UILabel *aToolbarLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [self addSubview:aToolbarLabel];
    self.toolbarLabel = aToolbarLabel;
    [aToolbarLabel release];
    
    [self layoutNote];
    
    CGFloat inset;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        inset = kBlioNotesViewPhoneShadow;
    } else {
        inset = kBlioNotesViewPadBorder;
    }
    
    UIFont *buttonFont = [UIFont boldSystemFontOfSize:12.0f];
	NSString *buttonText = NSLocalizedString(@"Cancel",@"\"Cancel\" button label for Notes View"); 
    UIImage *buttonImage = [UIImage imageWithString:buttonText font:buttonFont color:[UIColor blackColor]];
    
    UISegmentedControl *aButtonSegment = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:buttonImage]];
    aButtonSegment.segmentedControlStyle = UISegmentedControlStyleBar;
    aButtonSegment.frame = CGRectMake(inset + kBlioNotesViewTextXInset, inset + ((kBlioNotesViewToolbarHeight - aButtonSegment.frame.size.height)/2.0f), aButtonSegment.frame.size.width + 4, aButtonSegment.frame.size.height);
    aButtonSegment.tintColor = [UIColor colorWithRed:0.890 green:0.863f blue:0.592f alpha:1.0f];
    [[aButtonSegment imageForSegmentAtIndex:0] setAccessibilityLabel:NSLocalizedString(@"Cancel", @"Accessibility label for Notes View Cancel button")];

    [aButtonSegment addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventValueChanged];
    [aButtonSegment setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
    [self addSubview:aButtonSegment];
    [aButtonSegment release];
    
	buttonText = NSLocalizedString(@"Save",@"\"Save\" button label for Notes View");
    buttonImage = [UIImage imageWithString:buttonText font:buttonFont color:[UIColor blackColor]];
    
    aButtonSegment = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:buttonImage]];
    aButtonSegment.segmentedControlStyle = UISegmentedControlStyleBar;
    aButtonSegment.frame = CGRectMake(self.frame.size.width - inset - kBlioNotesViewTextXInset - aButtonSegment.frame.size.width - 8, inset + ((kBlioNotesViewToolbarHeight - aButtonSegment.frame.size.height)/2.0f), aButtonSegment.frame.size.width + 8, aButtonSegment.frame.size.height);
    aButtonSegment.tintColor = [UIColor colorWithRed:0.890 green:0.863f blue:0.592f alpha:1.0f];
    [[aButtonSegment imageForSegmentAtIndex:0] setAccessibilityLabel:NSLocalizedString(@"Save", @"Accessibility label for Notes View Save button")];

    [aButtonSegment addTarget:self action:@selector(save:) forControlEvents:UIControlEventValueChanged];
    [aButtonSegment setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    [self addSubview:aButtonSegment];
    [aButtonSegment release];
    
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateStyle:NSDateFormatterShortStyle];
    NSString *dateString = [dateFormat stringFromDate:date];  
    [dateFormat release];
    if (nil != self.page)
		toolbarLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Page %@, %@",@"\"Page %@, %@\" toolbar label for Notes View"), self.page, dateString];
    else
        toolbarLabel.text = [NSString stringWithFormat:@"%@", self.page, dateString];
    toolbarLabel.adjustsFontSizeToFitWidth = YES;
    //toolbarLabel.font = [UIFont boldSystemFontOfSize:14.0f];
    toolbarLabel.font = [UIFont fontWithName:@"Marker Felt" size:18.0f];
    toolbarLabel.backgroundColor = [UIColor clearColor];
    toolbarLabel.textAlignment = UITextAlignmentCenter;
    
    UITextView *aTextView = [[UITextView alloc] initWithFrame:
                             CGRectMake(inset + kBlioNotesViewTextXInset, 
                                        inset + kBlioNotesViewToolbarHeight + kBlioNotesViewTextTopInset, 
                                        self.frame.size.width - 2*(inset + kBlioNotesViewTextXInset), 
                                        self.frame.size.height - 2*inset - kBlioNotesViewTextTopInset - kBlioNotesViewTextBottomInset - kBlioNotesViewToolbarHeight)];
    //aTextView.font = [UIFont boldSystemFontOfSize:14.0f];
    aTextView.font = [UIFont fontWithName:@"Marker Felt" size:18.0f];
    aTextView.backgroundColor = [UIColor clearColor];
    aTextView.keyboardAppearance = UIKeyboardAppearanceAlert;
    [aTextView setText:[self.note valueForKey:@"noteText"]];
    [aTextView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [self addSubview:aTextView];
    self.textView = aTextView;
    [aTextView release];    
    
    if (animated) {
        CGFloat yOffscreen = -CGRectGetMaxY(self.frame);
        self.transform = CGAffineTransformMakeTranslation(0, yOffscreen);
        [UIView beginAnimations:BlioNotesViewShowFromTopAnimation context:nil];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationWillStartSelector:@selector(animationWillStart:context:)];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDuration:0.35f];
        self.transform = CGAffineTransformIdentity;
        [UIView commitAnimations];
    } else {
        [self.textView becomeFirstResponder];
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.layer.shadowOpacity = 0.3f;
        self.layer.shadowRadius = 20.0f;
        self.layer.shadowOffset = CGSizeZero;
    }

}

- (void)keyboardDidShow:(NSNotification *)notification {
    NSDictionary* info = [notification userInfo];
    
    CGRect keyboardRect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    keyboardRect = [[self superview] convertRect:keyboardRect fromView:nil];

    bottomInset = keyboardRect.size.height;
    
    [UIView beginAnimations:@"keyboardAdjust" context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.35f];
    [self layoutNote];
    [UIView commitAnimations];
}

- (void)layoutSubviews {
    [self layoutNote];
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
    
    CGPoint topCenter = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
    CGPoint bottomCenter = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
    CGContextDrawLinearGradient(c, glossGradient, topCenter, bottomCenter, 0);    
    CGGradientRelease(glossGradient);
    CGColorSpaceRelease(rgbColorspace);
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

- (void)drawRect:(CGRect)rect {
    // Drawing code
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGFloat inset;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        inset = kBlioNotesViewPhoneShadow;
        CGContextSetShadowWithColor(ctx, CGSizeZero, kBlioNotesViewPhoneShadow, [UIColor colorWithWhite:0.3f alpha:0.8f].CGColor);
    } else {
        inset = kBlioNotesViewPadBorder;
    }
    
    CGRect inRect = CGRectInset(rect, inset, inset);
    CGContextBeginTransparencyLayer(ctx, NULL);
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        CGContextBeginPath(ctx);
        addRoundedRectToPath(ctx, 7.0f, rect);
        CGContextClip(ctx); 
        CGContextSetRGBFillColor(ctx, 0.877f, 0.868f, 0.602f, 0.95f);
        CGContextFillRect(ctx, rect);
        CGRect glossRect = rect;
        glossRect.size.height = 26.0f;
        drawGlossGradient(ctx, glossRect);
    }
	
    CGFloat components[8] = { 0.996f, 0.976f, 0.718f, 1.0f,  // Start color
        0.996f, 0.969f, 0.537f, 1.0f }; // End color
    
    CGColorSpaceRef myColorspace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef myGradient = CGGradientCreateWithColorComponents (myColorspace, components, NULL, 2);
    CGColorSpaceRelease(myColorspace);
    
    CGContextSaveGState(ctx);
    CGContextClipToRect(ctx, inRect);
    CGContextDrawLinearGradient (ctx, myGradient, CGPointMake(CGRectGetMinX(inRect), CGRectGetMinY(inRect)), CGPointMake(CGRectGetMinX(inRect), CGRectGetMaxY(inRect)), 0);
    CGGradientRelease(myGradient);
    
    CGContextSetRGBFillColor(ctx, 1.0f, 1.0f, 1.0f, 0.7f);
    
    CGContextSetShadow(ctx, CGSizeMake(0,1), 0);
    CGContextFillRect(ctx, CGRectMake(inRect.origin.x + kBlioNotesViewTextXInset, inRect.origin.y + kBlioNotesViewToolbarHeight + 1, inRect.size.width - 2 * kBlioNotesViewTextXInset, 1));
    
    CGContextRestoreGState(ctx);
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {        
        CGContextBeginPath(ctx);
        addRoundedRectToPath(ctx, 7.0f, rect);
        CGContextSetLineWidth(ctx, 2.0f);
        CGContextSetRGBStrokeColor(ctx, 0.491f, 0.486f, 0.342f, 1.0f);
        CGContextSetShadowWithColor(ctx, CGSizeMake(0, 1), 0, [UIColor colorWithWhite:1 alpha:0.3f].CGColor);
        CGContextStrokePath(ctx);

    }
    
    CGContextEndTransparencyLayer(ctx);
}

- (void)dismiss:(id)sender {
    [self.textView resignFirstResponder];
    CGFloat yOffscreen = -CGRectGetMaxY(self.frame);
    
    [UIView beginAnimations:BlioNotesViewExitToTopAnimation context:self];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationDuration:0.35f];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    self.transform = CGAffineTransformMakeTranslation(0, yOffscreen);
    [UIView commitAnimations];
    
    [self.showInView setUserInteractionEnabled:YES];
	
	// Remove highlight if there was no pre-existing note and
	// we didn't just save a new one.  (We can't just use "!self.note"
	// because a note we just saved may not have yet been persisted.)
	if (!self.note  && !self.noteSaved) {
		if ([self.delegate respondsToSelector:@selector(removeHighlightAtRange:)])
			[self.delegate performSelector:@selector(removeHighlightAtRange:) withObject:self.range]; 
	}
	self.noteSaved = NO;
    
}

- (void)save:(id)sender {
    if (nil != self.note) {
        if ([self.delegate respondsToSelector:@selector(notesViewUpdateNote:)])
            [self.delegate performSelector:@selector(notesViewUpdateNote:) withObject:self];
    } else {
        if ([self.delegate respondsToSelector:@selector(notesViewCreateNote:)])
            [self.delegate performSelector:@selector(notesViewCreateNote:) withObject:self];
    }
    [self dismiss:sender];
}
                
- (void)animationWillStart:(NSString *)animationID context:(void *)context {
    if ([animationID isEqualToString:BlioNotesViewShowFromTopAnimation]) {
        [self.textView becomeFirstResponder];
    }
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
     if ([animationID isEqualToString:BlioNotesViewExitToTopAnimation]) {
        [(UIView *)context removeFromSuperview];
    
        if ([self.delegate respondsToSelector:@selector(notesViewDismissed)])
            [(NSObject *)self.delegate performSelector:@selector(notesViewDismissed) withObject:nil afterDelay:0.2f];
    }
    
    
}                                                  


@end
