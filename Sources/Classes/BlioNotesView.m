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

@synthesize page, textView, delegate, note;

- (void)dealloc {
    self.page = nil;
    self.textView = nil;
    self.delegate = nil;
    self.note = nil;
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame {
    return [self initWithPage:nil];
}

- (id)initWithPage:(NSString *)pageNumber {
    return [self initWithPage:pageNumber note:nil];
}

- (id)initWithPage:(NSString *)pageNumber note:(NSManagedObject *)aNote {
    if ((self = [super initWithFrame:CGRectZero])) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        self.page = pageNumber;
        self.note = aNote;
    }
    return self;
}

- (void)showInView:(UIView *)view {
    [self showInView:view animated:YES];
}

- (void)showInView:(UIView *)view animated:(BOOL)animated {
    [self removeFromSuperview];
    
    CGRect newFrame = CGRectMake(0, 
                                 (view.bounds.size.height - (2 * kBlioNotesViewShadow + kBlioNotesViewNoteHeight))/2.0f + kBlioNotesViewNoteYInset,
                                 view.bounds.size.width,
                                 2 * kBlioNotesViewShadow + kBlioNotesViewNoteHeight);
    self.frame = newFrame;
    [view addSubview:self];
    
    UIFont *buttonFont = [UIFont boldSystemFontOfSize:12.0f];
    NSString *buttonText = @"Cancel";
    UIImage *buttonImage = [UIImage imageWithString:buttonText font:buttonFont color:[UIColor blackColor]];

    UISegmentedControl *aButtonSegment = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:buttonImage]];
    aButtonSegment.segmentedControlStyle = UISegmentedControlStyleBar;
    aButtonSegment.frame = CGRectMake(kBlioNotesViewShadow + kBlioNotesViewTextXInset, kBlioNotesViewShadow + ((kBlioNotesViewToolbarHeight - aButtonSegment.frame.size.height)/2.0f), aButtonSegment.frame.size.width + 4, aButtonSegment.frame.size.height);
    aButtonSegment.tintColor = [UIColor colorWithRed:0.890 green:0.863f blue:0.592f alpha:1.0f];
    [aButtonSegment addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:aButtonSegment];
    [aButtonSegment release];
    
    buttonText = @"Save";
    buttonImage = [UIImage imageWithString:buttonText font:buttonFont color:[UIColor blackColor]];

    aButtonSegment = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:buttonImage]];
    aButtonSegment.segmentedControlStyle = UISegmentedControlStyleBar;
    aButtonSegment.frame = CGRectMake(newFrame.size.width - kBlioNotesViewShadow - kBlioNotesViewTextXInset - aButtonSegment.frame.size.width - 8, kBlioNotesViewShadow + ((kBlioNotesViewToolbarHeight - aButtonSegment.frame.size.height)/2.0f), aButtonSegment.frame.size.width + 8, aButtonSegment.frame.size.height);
    aButtonSegment.tintColor = [UIColor colorWithRed:0.890 green:0.863f blue:0.592f alpha:1.0f];
    [aButtonSegment addTarget:self action:@selector(save:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:aButtonSegment];
    [aButtonSegment release];
    
    UILabel *toolbarLabel = [[UILabel alloc] initWithFrame:CGRectMake((newFrame.size.width - kBlioNotesViewToolbarLabelWidth)/2.0f, kBlioNotesViewShadow, kBlioNotesViewToolbarLabelWidth, kBlioNotesViewToolbarHeight)];
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
    [self addSubview:toolbarLabel];
    [toolbarLabel release];
    
    UITextView *aTextView = [[UITextView alloc] initWithFrame:
                             CGRectMake(kBlioNotesViewShadow + kBlioNotesViewTextXInset, 
                                        kBlioNotesViewShadow + kBlioNotesViewToolbarHeight + kBlioNotesViewTextTopInset, 
                                        newFrame.size.width - 2*(kBlioNotesViewShadow + kBlioNotesViewTextXInset), 
                                        newFrame.size.height - 2*kBlioNotesViewShadow - kBlioNotesViewTextTopInset - kBlioNotesViewTextBottomInset - kBlioNotesViewToolbarHeight)];
    //aTextView.font = [UIFont boldSystemFontOfSize:14.0f];
    aTextView.font = [UIFont fontWithName:@"Marker Felt" size:18.0f];
    aTextView.backgroundColor = [UIColor clearColor];
    [aTextView setText:[self.note valueForKey:@"noteText"]];
    [aTextView becomeFirstResponder];
    [self addSubview:aTextView];
    self.textView = aTextView;
    [aTextView release];
    
    if (animated) {
        CGFloat yOffscreen = -CGRectGetMaxY(newFrame);
        self.transform = CGAffineTransformMakeTranslation(0, yOffscreen);
        [UIView beginAnimations:@"showFromTop" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDuration:0.35f];
        self.transform = CGAffineTransformIdentity;
        [UIView commitAnimations];
    }
                        
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
}                                                  


@end
