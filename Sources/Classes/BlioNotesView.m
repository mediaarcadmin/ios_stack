//
//  BlioNotesView.m
//  BlioApp
//
//  Created by matt on 31/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import "BlioNotesView.h"
#import "BlioUIImageAdditions.h"

static const CGFloat kBlioNotesViewShadow = 16;
static const CGFloat kBlioNotesViewNoteHeight = 200;
static const CGFloat kBlioNotesViewNoteYInset = -40;
static const CGFloat kBlioNotesViewToolbarHeight = 44;
static const CGFloat kBlioNotesViewToolbarLabelWidth = 140;
static const CGFloat kBlioNotesViewTextXInset = 8;
static const CGFloat kBlioNotesViewTextTopInset = 8;
static const CGFloat kBlioNotesViewTextBottomInset = 24;


@implementation BlioNotesView

@synthesize page, textView, delegate, note, range, toolbarLabel;

- (void)dealloc {
    self.page = nil;
    self.textView = nil;
    self.toolbarLabel = nil;
    self.delegate = nil;
    self.note = nil;
    self.range = nil;
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
        self.range = aRange;
        // Setting this forces layoutSubviews to be called on a rotation
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.autoresizesSubviews = YES;
    }
    return self;
}

- (void)showInView:(UIView *)view {
    [self showInView:view animated:YES];
}

- (void)layoutNote {
    UIView *view = [self superview];
    CGRect newFrame = CGRectMake(0, 
                                 (view.bounds.size.height - (2 * kBlioNotesViewShadow + kBlioNotesViewNoteHeight))/2.0f + kBlioNotesViewNoteYInset,
                                 view.bounds.size.width,
                                 2 * kBlioNotesViewShadow + kBlioNotesViewNoteHeight);
    self.frame = newFrame;
    self.toolbarLabel.frame = CGRectMake((newFrame.size.width - kBlioNotesViewToolbarLabelWidth)/2.0f, kBlioNotesViewShadow, kBlioNotesViewToolbarLabelWidth, kBlioNotesViewToolbarHeight);
    [self setNeedsDisplay];
}

- (void)showInView:(UIView *)view animated:(BOOL)animated {
    [self removeFromSuperview];
    [view addSubview:self];
    
    UILabel *aToolbarLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [self addSubview:aToolbarLabel];
    self.toolbarLabel = aToolbarLabel;
    [aToolbarLabel release];
    
    [self layoutNote];
    
    UIFont *buttonFont = [UIFont boldSystemFontOfSize:12.0f];
    NSString *buttonText = @"Cancel";
    UIImage *buttonImage = [UIImage imageWithString:buttonText font:buttonFont color:[UIColor blackColor]];
    
    UISegmentedControl *aButtonSegment = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:buttonImage]];
    aButtonSegment.segmentedControlStyle = UISegmentedControlStyleBar;
    aButtonSegment.frame = CGRectMake(kBlioNotesViewShadow + kBlioNotesViewTextXInset, kBlioNotesViewShadow + ((kBlioNotesViewToolbarHeight - aButtonSegment.frame.size.height)/2.0f), aButtonSegment.frame.size.width + 4, aButtonSegment.frame.size.height);
    aButtonSegment.tintColor = [UIColor colorWithRed:0.890 green:0.863f blue:0.592f alpha:1.0f];
    [[aButtonSegment imageForSegmentAtIndex:0] setAccessibilityLabel:NSLocalizedString(@"Cancel", @"Accessibility label for Notes View Cancel button")];

    [aButtonSegment addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventValueChanged];
    [aButtonSegment setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
    [self addSubview:aButtonSegment];
    [aButtonSegment release];
    
    buttonText = @"Save";
    buttonImage = [UIImage imageWithString:buttonText font:buttonFont color:[UIColor blackColor]];
    
    aButtonSegment = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:buttonImage]];
    aButtonSegment.segmentedControlStyle = UISegmentedControlStyleBar;
    aButtonSegment.frame = CGRectMake(self.frame.size.width - kBlioNotesViewShadow - kBlioNotesViewTextXInset - aButtonSegment.frame.size.width - 8, kBlioNotesViewShadow + ((kBlioNotesViewToolbarHeight - aButtonSegment.frame.size.height)/2.0f), aButtonSegment.frame.size.width + 8, aButtonSegment.frame.size.height);
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
        toolbarLabel.text = [NSString stringWithFormat:@"Page %@, %@", self.page, dateString];
    else
        toolbarLabel.text = [NSString stringWithFormat:@"%@", self.page, dateString];
    toolbarLabel.adjustsFontSizeToFitWidth = YES;
    //toolbarLabel.font = [UIFont boldSystemFontOfSize:14.0f];
    toolbarLabel.font = [UIFont fontWithName:@"Marker Felt" size:18.0f];
    toolbarLabel.backgroundColor = [UIColor clearColor];
    toolbarLabel.textAlignment = UITextAlignmentCenter;
    
    UITextView *aTextView = [[UITextView alloc] initWithFrame:
                             CGRectMake(kBlioNotesViewShadow + kBlioNotesViewTextXInset, 
                                        kBlioNotesViewShadow + kBlioNotesViewToolbarHeight + kBlioNotesViewTextTopInset, 
                                        self.frame.size.width - 2*(kBlioNotesViewShadow + kBlioNotesViewTextXInset), 
                                        self.frame.size.height - 2*kBlioNotesViewShadow - kBlioNotesViewTextTopInset - kBlioNotesViewTextBottomInset - kBlioNotesViewToolbarHeight)];
    //aTextView.font = [UIFont boldSystemFontOfSize:14.0f];
    aTextView.font = [UIFont fontWithName:@"Marker Felt" size:18.0f];
    aTextView.backgroundColor = [UIColor clearColor];
    [aTextView setText:[self.note valueForKey:@"noteText"]];
    [aTextView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [aTextView becomeFirstResponder];
    [self addSubview:aTextView];
    self.textView = aTextView;
    [aTextView release];    
    
    if (animated) {
        CGFloat yOffscreen = -CGRectGetMaxY(self.frame);
        self.transform = CGAffineTransformMakeTranslation(0, yOffscreen);
        [UIView beginAnimations:@"showFromTop" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDuration:0.35f];
        self.transform = CGAffineTransformIdentity;
        [UIView commitAnimations];
    }    
}

- (void)layoutSubviews {
    NSLog(@"Laying out note");
    [self layoutNote];
}

- (void)drawRect:(CGRect)rect {
    // Drawing code
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect inRect = CGRectInset(rect, kBlioNotesViewShadow, kBlioNotesViewShadow);
    CGContextSetShadowWithColor(ctx, CGSizeZero, kBlioNotesViewShadow, [UIColor colorWithWhite:0.3f alpha:0.8f].CGColor);
    CGContextBeginTransparencyLayer(ctx, NULL);

    CGFloat components[8] = { 0.996f, 0.976f, 0.718f, 1.0f,  // Start color
        0.996f, 0.969f, 0.537f, 1.0f }; // End color
    
    CGColorSpaceRef myColorspace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef myGradient = CGGradientCreateWithColorComponents (myColorspace, components, NULL, 2);
    CGColorSpaceRelease(myColorspace);
    CGContextClipToRect(ctx, inRect);
    CGContextDrawLinearGradient (ctx, myGradient, CGPointMake(CGRectGetMinX(inRect), CGRectGetMinY(inRect)), CGPointMake(CGRectGetMinX(inRect), CGRectGetMaxY(inRect)), 0);
    CGGradientRelease(myGradient);
    
    CGContextSetLineWidth(ctx, 1.0f);
    CGContextSetRGBStrokeColor(ctx, 1.0f, 1.0f, 1.0f, 1.0f);
    CGContextSaveGState(ctx);
    CGContextSetShadow(ctx, CGSizeMake(0,0.5f), 0.5f);
    CGContextStrokeRect(ctx, CGRectMake(inRect.origin.x + kBlioNotesViewTextXInset, inRect.origin.y + kBlioNotesViewToolbarHeight + 1, inRect.size.width - 2 * kBlioNotesViewTextXInset, 0));
    CGContextRestoreGState(ctx);
    CGContextEndTransparencyLayer(ctx);
}

- (void)dismiss:(id)sender {
    [self.textView resignFirstResponder];
    CGFloat yOffscreen = -CGRectGetMaxY(self.frame);
    
    [UIView beginAnimations:@"exitToTop" context:self];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationDuration:0.35f];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    self.transform = CGAffineTransformMakeTranslation(0, yOffscreen);
    [UIView commitAnimations];
    
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
                                                  
- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    [(UIView *)context removeFromSuperview];
    
    if ([self.delegate respondsToSelector:@selector(notesViewDismissed)])
        [(NSObject *)self.delegate performSelector:@selector(notesViewDismissed) withObject:nil afterDelay:0.2f];
}                                                  


@end
