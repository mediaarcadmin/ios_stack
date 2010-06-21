//
//  BlioBookSearchToolbar.m
//  BlioApp
//
//  Created by matt on 15/06/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioBookSearchToolbar.h"

@interface BlioBookSearchToolbar()
@property (nonatomic, retain) UIToolbar *toolbar;
@property (nonatomic, retain) UIBarButtonItem *doneButton;
@end


@implementation BlioBookSearchToolbar

@synthesize searchBar, toolbar, doneButton, delegate;

- (void)dealloc {
    self.searchBar = nil;
    self.toolbar = nil;
    self.doneButton = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)init {
    if ((self = [super init])) {
        // Initialization code       
        [self setClipsToBounds:YES];
        [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        
        UIToolbar *aToolbar = [[UIToolbar alloc] init];
        [aToolbar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [self addSubview:aToolbar];
        self.toolbar = aToolbar;
        [aToolbar release];
        
        UIBarButtonItem *flexible = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
        
        UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(done:)];
        [aToolbar setItems:[NSArray arrayWithObjects:done, flexible, nil]];
        self.doneButton = done;
        [done release];
        
        UISearchBar *aSearchBar = [[UISearchBar alloc] init];
        [aSearchBar setPlaceholder:NSLocalizedString(@"Search",@"\"Search\" placeholder text in Search bar")];
        //UIColor *matchedTintColor = [UIColor colorWithHue:0.595 saturation:0.267 brightness:0.68 alpha:1];
        //[aSearchBar setTintColor:matchedTintColor];
        //[aSearchBar setDelegate:self];
        [aSearchBar setShowsCancelButton:NO];
        [aSearchBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        //[self.navigationItem setTitleView:aSearchBar];
        [self addSubview:aSearchBar];
        self.searchBar = aSearchBar;
        [aSearchBar release];

    }
    return self;
}

- (void)layoutSubviews {
    [self.toolbar setFrame:self.bounds];
    CGFloat doneWidth = [self.doneButton.title sizeWithFont:[UIFont boldSystemFontOfSize:12.0f]].width + 10*2 + 6*2;
    [self.searchBar setFrame:CGRectMake(doneWidth, 1, CGRectGetWidth(self.bounds) - doneWidth, CGRectGetHeight(self.bounds))];
}

- (void)setTintColor:(UIColor *)tintColor {
    [self.searchBar setTintColor:tintColor];
    [self.toolbar setTintColor:tintColor];
}

- (void)setDelegate:(id<BlioBookSearchToolbarDelegate>)newDelegate {
    delegate = newDelegate;
    [self.searchBar setDelegate:newDelegate];
}

- (void)done:(id)sender {
    if ([(NSObject *)self.delegate respondsToSelector:@selector(dismissSearchToolbar:)])
        [self.delegate dismissSearchToolbar:sender];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


@end
