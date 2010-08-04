//
//  BlioBookSearchToolbar.m
//  BlioApp
//
//  Created by matt on 15/06/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioBookSearchToolbar.h"
#import "BlioAccessibilitySegmentedControl.h"
#import "BlioUIImageAdditions.h"

@interface BlioBookSearchToolbarDecoration : UIView
@end

@interface BlioBookSearchToolbar()
@property (nonatomic, retain) UINavigationBar *doneNavBar;
@property (nonatomic, retain) UIBarButtonItem *doneButton;
@property (nonatomic, retain) UINavigationBar *inlineNavBar;
@property (nonatomic, retain) UISegmentedControl *inlineSegmentedControl;
@property (nonatomic, retain) UIView *toolbarDecoration;
@end


@implementation BlioBookSearchToolbar

@synthesize searchBar, doneNavBar, doneButton, delegate, inlineNavBar, inlineSegmentedControl, inlineMode, toolbarDecoration;

- (void)dealloc {
    self.searchBar = nil;
    self.doneNavBar = nil;
    self.doneButton = nil;
    self.inlineNavBar = nil;
    self.inlineSegmentedControl = nil;
    self.toolbarDecoration = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)init {
    if ((self = [super init])) {
        // Initialization code    
        [self setBackgroundColor:[UIColor clearColor]];
        [self setClipsToBounds:YES];
        [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        
        UINavigationBar *aNavBar = [[UINavigationBar alloc] init];
        self.doneNavBar = aNavBar;
        [self addSubview:aNavBar];
        [aNavBar release];
                
        UIBarButtonItem *aButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self action:@selector(done:)];
        self.doneButton = aButton;
        [aButton release];
        
        UINavigationItem *aNavItem = [[UINavigationItem alloc] init];
        [aNavItem setRightBarButtonItem:self.doneButton];
        [self.doneNavBar setItems:[NSArray arrayWithObject:aNavItem] animated:NO];
        [aNavItem release];
        
        aNavBar = [[UINavigationBar alloc] init];
        self.inlineNavBar = aNavBar;
        [self addSubview:aNavBar];
        [aNavBar release];
                
        NSArray *segmentImages = [NSArray arrayWithObjects:
                                  [UIImage imageNamed:@"buttonBarArrowUpSmall.png"],
                                  [UIImage imageNamed:@"buttonBarArrowDownSmall.png"],
                                  nil];
        
        BlioAccessibilitySegmentedControl *aInlineSegmentedControl = [[BlioAccessibilitySegmentedControl alloc] initWithItems:segmentImages];
        aInlineSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        aInlineSegmentedControl.momentary = YES;
        [aInlineSegmentedControl addTarget:self action:@selector(inlineSegmentChanged:) forControlEvents:UIControlEventValueChanged];
        
        [[aInlineSegmentedControl imageForSegmentAtIndex:0] setAccessibilityLabel:NSLocalizedString(@"Find previous", @"Accessibility label for Book Search Find Previous button")];
        [[aInlineSegmentedControl imageForSegmentAtIndex:0] setAccessibilityHint:NSLocalizedString(@"Searches backwards for the previous occurence of the search term.", @"Accessibility hint for Book Search Find Previous button")];
        [[aInlineSegmentedControl imageForSegmentAtIndex:1] setAccessibilityLabel:NSLocalizedString(@"Find next", @"Accessibility label for Book Search Find Next button")];
        [[aInlineSegmentedControl imageForSegmentAtIndex:1] setAccessibilityHint:NSLocalizedString(@"Searches forwards for the next occurence of the search term.", @"Accessibility hint for Book Search Find Next button")];
        
        CGRect segmentFrame = aInlineSegmentedControl.frame;
        segmentFrame.size.width = 88;
        [aInlineSegmentedControl setFrame:segmentFrame];
        self.inlineSegmentedControl = aInlineSegmentedControl;
        [aInlineSegmentedControl release];
        
        aButton = [[UIBarButtonItem alloc] initWithCustomView:self.inlineSegmentedControl];
        aNavItem = [[UINavigationItem alloc] init];
        [aNavItem setRightBarButtonItem:aButton];
        [self.inlineNavBar setItems:[NSArray arrayWithObject:aNavItem] animated:NO];
        [aButton release];
        [aNavItem release];
        
        UISearchBar *aSearchBar = [[UISearchBar alloc] init];
        [aSearchBar setPlaceholder:NSLocalizedString(@"Search",@"\"Search\" placeholder text in Search bar")];
        [aSearchBar setShowsCancelButton:NO];
        [aSearchBar setBackgroundColor:[UIColor clearColor]];
        [aSearchBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [self addSubview:aSearchBar];
        self.searchBar = aSearchBar;
        [aSearchBar release];
        
        BlioBookSearchToolbarDecoration *aToolbarDecoration = [[BlioBookSearchToolbarDecoration alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), 2)];
        [aToolbarDecoration setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [self addSubview:aToolbarDecoration];
        self.toolbarDecoration = aToolbarDecoration;
        [aToolbarDecoration release];
    }
    return self;
}

- (void)setFrame:(CGRect)newFrame {
    [super setFrame:newFrame];
}

- (void)layoutSubviews {
    CGFloat doneWidth = [self.doneButton.title sizeWithFont:[UIFont boldSystemFontOfSize:12.0f]].width + 10*2 + 6*2;
    [self.doneNavBar setFrame:CGRectMake(0, 0, doneWidth, CGRectGetHeight(self.bounds))];
    
    CGFloat inlineWidth = CGRectGetWidth(self.inlineSegmentedControl.frame) + 6*2;
    
    if (self.inlineMode) {
        [self.inlineSegmentedControl setAlpha:1];
        [self.toolbarDecoration setAlpha:1];
        [self.inlineNavBar setFrame:CGRectMake(CGRectGetWidth(self.bounds) - inlineWidth, 0, inlineWidth, CGRectGetHeight(self.bounds))];
        [self.searchBar setFrame:CGRectMake(doneWidth, 0, CGRectGetWidth(self.bounds) - doneWidth - inlineWidth, CGRectGetHeight(self.bounds))];
    } else {
        [self.inlineSegmentedControl setAlpha:0];
        [self.toolbarDecoration setAlpha:0];
        [self.inlineNavBar setFrame:CGRectMake(CGRectGetWidth(self.bounds), 0, inlineWidth, CGRectGetHeight(self.bounds))];
        [self.searchBar setFrame:CGRectMake(doneWidth, 0, CGRectGetWidth(self.bounds) - doneWidth, CGRectGetHeight(self.bounds))];
    }
    
    [self.searchBar layoutSubviews];
}

- (void)inlineSegmentChanged:(id)sender {
    NSInteger newSegment = [sender selectedSegmentIndex];
    if (newSegment == 1) {
        if ([(NSObject *)self.delegate respondsToSelector:@selector(nextResult)])
            [self.delegate nextResult];
    } else {
        if ([(NSObject *)self.delegate respondsToSelector:@selector(nextResult)])
            [self.delegate previousResult];
    }
}

- (void)setInlineMode:(BOOL)newInlineMode {
    inlineMode = newInlineMode;
    [self layoutSubviews];
}

- (void)setTintColor:(UIColor *)tintColor {
    [self.searchBar setTintColor:tintColor];
    [self.doneNavBar setTintColor:tintColor];
    [self.inlineNavBar setTintColor:tintColor];
    [self.inlineSegmentedControl setTintColor:tintColor];
}

- (void)setBarStyle:(UIBarStyle)barStyle {
    [self.searchBar setBarStyle:barStyle];
    [self.doneNavBar setBarStyle:barStyle];
    [self.inlineNavBar setBarStyle:barStyle];
}

- (void)setDelegate:(id<BlioBookSearchToolbarDelegate>)newDelegate {
    delegate = newDelegate;
    [self.searchBar setDelegate:newDelegate];
}

- (void)done:(id)sender {
    if ([(NSObject *)self.delegate respondsToSelector:@selector(dismissSearchToolbar:)])
        [self.delegate dismissSearchToolbar:sender];
}

@end
         
@implementation BlioBookSearchToolbarDecoration

- (id)init {
    if ((self = [super init])) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextClearRect(ctx, rect);

    CGContextSetRGBFillColor(ctx, 0.65f, 0.65f, 0.65f, 0.3f);
    CGContextFillRect(ctx, CGRectMake(CGRectGetMinX(rect), CGRectGetMinY(rect), CGRectGetWidth(rect), 1));
    
    CGContextSetRGBFillColor(ctx, 1, 1, 1, 0.69f);
    CGContextFillRect(ctx, CGRectMake(CGRectGetMinX(rect), CGRectGetMinY(rect) + 1, CGRectGetWidth(rect), 1));
}

@end
