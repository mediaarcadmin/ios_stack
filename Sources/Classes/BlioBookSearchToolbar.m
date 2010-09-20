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
#import <libEucalyptus/THUIImageAdditions.h>

@interface BlioBookSearchCustomSearchField : UITextField
@end

@interface BlioBookSearchCustomNavigationBar : UINavigationBar
@end

@interface BlioBookSearchCustomSearchBar : UIView <BlioBookSearchBar, UITextFieldDelegate> { // UISearchBar with transparent surround
    BlioBookSearchCustomSearchField *searchField;
    id<UISearchBarDelegate> delegate;
}

@property (nonatomic, retain) BlioBookSearchCustomSearchField *searchField;
@property (nonatomic, retain) id<UISearchBarDelegate> delegate;

@end

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
        
        UINavigationBar *aNavBar;
        UIBarButtonItem *aButton;
        UINavigationItem *aNavItem;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            aNavBar = [[UINavigationBar alloc] init];
            self.doneNavBar = aNavBar;
            [self addSubview:aNavBar];
            [aNavBar release];
            
            aButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self action:@selector(done:)];
            self.doneButton = aButton;
            [aButton release];
            
            aNavItem = [[UINavigationItem alloc] init];
            [aNavItem setRightBarButtonItem:self.doneButton];
            [self.doneNavBar setItems:[NSArray arrayWithObject:aNavItem] animated:NO];
            [aNavItem release];
        }
        
        aNavBar = [[BlioBookSearchCustomNavigationBar alloc] init];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            aNavBar.backgroundColor = [UIColor clearColor];
            aNavBar.tintColor = [UIColor colorWithRed:0.100 green:0.152 blue:0.326 alpha:1.000];
        }
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
        [[aInlineSegmentedControl imageForSegmentAtIndex:0] setAccessibilityHint:NSLocalizedString(@"Searches backwards for the previous occurrence of the search term.", @"Accessibility hint for Book Search Find Previous button")];
        [[aInlineSegmentedControl imageForSegmentAtIndex:1] setAccessibilityLabel:NSLocalizedString(@"Find next", @"Accessibility label for Book Search Find Next button")];
        [[aInlineSegmentedControl imageForSegmentAtIndex:1] setAccessibilityHint:NSLocalizedString(@"Searches forward for the next occurrence of the search term.", @"Accessibility hint for Book Search Find Next button")];
        
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
        
        UIView <BlioBookSearchBar> *aSearchBar;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            aSearchBar = [[UISearchBar alloc] init];            
        } else {
            aSearchBar = [[BlioBookSearchCustomSearchBar alloc] init];
        }
        [aSearchBar setPlaceholder:NSLocalizedString(@"Search",@"\"Search\" placeholder text in Search bar")];
        [aSearchBar setShowsCancelButton:NO];
        [aSearchBar setBarStyle:UIBarStyleBlackOpaque];
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

- (void)layoutSubviews {
    CGFloat doneWidth = 0;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        doneWidth = [self.doneButton.title sizeWithFont:[UIFont boldSystemFontOfSize:12.0f]].width + 10*2 + 6*2;
        [self.doneNavBar setFrame:CGRectMake(0, 0, doneWidth, CGRectGetHeight(self.bounds))];
    }
    
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
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.searchBar setTintColor:tintColor];
        [self.doneNavBar setTintColor:tintColor];
        [self.inlineNavBar setTintColor:tintColor];
        [self.inlineSegmentedControl setTintColor:tintColor];
    } else {
        self.inlineSegmentedControl.tintColor = [UIColor colorWithRed:0.000 green:0.046 blue:0.121 alpha:1.000];
    }
}

- (void)setBarStyle:(UIBarStyle)barStyle {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.searchBar setBarStyle:barStyle];
        [self.doneNavBar setBarStyle:barStyle];
        [self.inlineNavBar setBarStyle:barStyle];
    }
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

@implementation BlioBookSearchCustomSearchBar


@synthesize searchField, delegate;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.searchField = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)init {
    if ((self = [super init])) {
        self.autoresizesSubviews = YES;
        
        UIImageView *aSearchView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"searchFieldIcon.png"]];
        
        BlioBookSearchCustomSearchField *aSearchField = [[BlioBookSearchCustomSearchField alloc] init];
        aSearchField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        aSearchField.background = [UIImage stretchableImageNamed:@"searchBarBorder.png" leftCapWidth:17 topCapHeight:16];
        aSearchField.clearButtonMode = UITextFieldViewModeAlways;
        aSearchField.leftView = aSearchView;
        aSearchField.leftViewMode = UITextFieldViewModeAlways;
        aSearchField.textColor = [UIColor darkTextColor];
        aSearchField.font = [UIFont systemFontOfSize:14];
        aSearchField.delegate = self;
        aSearchField.returnKeyType = UIReturnKeySearch;
        aSearchField.autocorrectionType = UITextAutocorrectionTypeNo; // Matches a searchBar
        [self addSubview:aSearchField];
        self.searchField = aSearchField;
        [aSearchField release];
        [aSearchView release];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchTextDidChange:) name:UITextFieldTextDidChangeNotification object:self.searchField];
    }
    return self;
}

- (void)setPlaceholder:(NSString *)placeholder {
    [self.searchField setPlaceholder:placeholder];
}

- (void)setShowsCancelButton:(BOOL)showCancel {
    // Do nothing
}

- (void)setBarStyle:(UIBarStyle)barStyle {
    // Do nothing
}

- (void)setTintColor:(UIColor *)tintColor {
    // Do nothing
}

- (NSString *)text {
    return self.searchField.text;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    BOOL ret = YES;
    if ([self.delegate respondsToSelector:@selector(searchBarShouldBeginEditing:)]) {
        ret = [self.delegate searchBarShouldBeginEditing:(id)self];
    }
    return ret;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if ([self.delegate respondsToSelector:@selector(searchBarTextDidBeginEditing:)]) {
        [self.delegate searchBarTextDidBeginEditing:(id)self];
    }
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    BOOL ret = YES;
    if ([self.delegate respondsToSelector:@selector(searchBarShouldEndEditing:)]) {
        ret = [self.delegate searchBarShouldEndEditing:(id)self];
    }
    return ret;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([self.delegate respondsToSelector:@selector(searchBarTextDidEndEditing:)]) {
        [self.delegate searchBarTextDidEndEditing:(id)self];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    BOOL ret = YES;
    if ([self.delegate respondsToSelector:@selector(searchBar:shouldChangeTextInRange:replacementText:)]) {
        ret = [self.delegate searchBar:(id)self shouldChangeTextInRange:range replacementText:string];
    }
    
    return ret;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([self.delegate respondsToSelector:@selector(searchBarSearchButtonClicked:)]) {
        [self.delegate searchBarSearchButtonClicked:(id)self];
    }
    return YES;
}

- (void)searchTextDidChange:(NSNotification *)notification {
    if ([self.delegate respondsToSelector:@selector(searchBar:textDidChange:)]) {
        [self.delegate searchBar:(id)self textDidChange:[[notification object] text]];
    }
}

@end

static const CGFloat kBlioBookSearchCustomSearchFieldTextInset = 5;
static const CGFloat kBlioBookSearchCustomSearchFieldPaddingInset = 2;
static const CGFloat kBlioBookSearchCustomSearchFieldLeftViewInset = 9;
static const CGFloat kBlioBookSearchCustomSearchFieldClearButtonXInset = 5;
static const CGFloat kBlioBookSearchCustomSearchFieldClearButtonYInset = 1;
static const CGFloat kBlioBookSearchCustomSearchFieldTextPadding = 4;
static const CGFloat kBlioBookSearchCustomSearchBarXInset = 6;
static const CGFloat kBlioBookSearchCustomSearchBarHeight = 31;


@implementation BlioBookSearchCustomSearchField

- (CGRect)placeholderRectForBounds:(CGRect)bounds {
    return [self textRectForBounds:bounds];
}

- (CGRect)leftViewRectForBounds:(CGRect)bounds {
    CGRect rect = [super leftViewRectForBounds:bounds];
    rect.origin.x += kBlioBookSearchCustomSearchBarXInset + kBlioBookSearchCustomSearchFieldLeftViewInset;
    return rect;
}

- (CGRect)borderRectForBounds:(CGRect)bounds {
    CGRect insetRect = CGRectInset(bounds, kBlioBookSearchCustomSearchBarXInset, 0);
    insetRect.origin.y = floorf((CGRectGetHeight(insetRect) - kBlioBookSearchCustomSearchBarHeight)/2.0f);
    insetRect.size.height = kBlioBookSearchCustomSearchBarHeight;
    return insetRect;
}

- (CGRect)textRectForBounds:(CGRect)bounds {
    CGRect rect = [super textRectForBounds:bounds];
    rect.origin.x += kBlioBookSearchCustomSearchFieldTextInset;
    rect.size.width -= kBlioBookSearchCustomSearchFieldTextInset * 2;
    CGFloat textHeight = self.font.pointSize + kBlioBookSearchCustomSearchFieldTextPadding;
    rect.size.height = textHeight;
    rect.origin.y = floorf((CGRectGetHeight(bounds) - textHeight)/2.0f);
    
    return rect;
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
    return [self textRectForBounds:bounds];
}

- (CGRect)clearButtonRectForBounds:(CGRect)bounds {
    CGRect rect = [super clearButtonRectForBounds:bounds];
    rect.origin.x -= kBlioBookSearchCustomSearchFieldClearButtonXInset;
    rect.origin.y -= kBlioBookSearchCustomSearchFieldClearButtonYInset;
    return rect;
}

@end

@implementation BlioBookSearchCustomNavigationBar

- (void)drawRect:(CGRect)rect {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        CGContextClearRect(UIGraphicsGetCurrentContext(), rect);
    } else {
        [super drawRect:rect];
    }
}

@end



