//
//  BlioBookSearchToolbar.m
//  BlioApp
//
//  Created by matt on 15/06/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioBookSearchToolbar.h"

@interface BlioBookSearchToolbar()
@property (nonatomic, retain) UINavigationBar *navBar;
@property (nonatomic, retain) UIBarButtonItem *doneButton;
@end


@implementation BlioBookSearchToolbar

@synthesize searchBar, navBar, doneButton, delegate;

- (void)dealloc {
    self.searchBar = nil;
    self.navBar = nil;
    self.doneButton = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)init {
    if ((self = [super init])) {
        // Initialization code       
        [self setClipsToBounds:YES];
        [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        
        UINavigationBar *aNavBar = [[UINavigationBar alloc] init];
        [self addSubview:aNavBar];
        self.navBar = aNavBar;
        [self addSubview:aNavBar];
        [aNavBar release];
                
        UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(done:)];
        self.doneButton = done;
        [done release];
        
        UINavigationItem *aNavItem = [[UINavigationItem alloc] init];
        [aNavItem setRightBarButtonItem:done];
        [self.navBar setItems:[NSArray arrayWithObject:aNavItem] animated:NO];
        [aNavItem release];
        
        UISearchBar *aSearchBar = [[UISearchBar alloc] init];
        [aSearchBar setPlaceholder:NSLocalizedString(@"Search",@"\"Search\" placeholder text in Search bar")];
        [aSearchBar setShowsCancelButton:NO];
        
        [aSearchBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [self addSubview:aSearchBar];
        self.searchBar = aSearchBar;
        [aSearchBar release];
    }
    return self;
}

- (void)layoutSubviews {
    CGFloat doneWidth = [self.doneButton.title sizeWithFont:[UIFont boldSystemFontOfSize:12.0f]].width + 10*2 + 6*2;
    [self.navBar setFrame:CGRectMake(0, 0, doneWidth, CGRectGetHeight(self.bounds))];
    [self.searchBar setFrame:CGRectMake(doneWidth, 0, CGRectGetWidth(self.bounds) - doneWidth, CGRectGetHeight(self.bounds))];
}

- (void)setTintColor:(UIColor *)tintColor {
    [self.searchBar setTintColor:tintColor];
    [self.navBar setTintColor:tintColor];
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
