//
//  BlioBookSearchViewController.m
//  BlioApp
//
//  Created by matt on 07/06/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "BlioBookSearchViewController.h"
#import "BlioBookViewController.h"
#import "UIDevice+BlioAdditions.h"

#define BLIOBOOKSEARCHCELLPAGETAG 1233
#define BLIOBOOKSEARCHCELLPREFIXTAG 1234
#define BLIOBOOKSEARCHCELLMATCHTAG 1235
#define BLIOBOOKSEARCHCELLSUFFIXTAG 1236

#define RESULTSPREFIXSTRINGMAXLENGTH 15

static NSString * const BlioBookSearchDisplayOffScreenAnimation = @"BlioBookSearchDisplayOffScreenAnimation";
static NSString * const BlioBookSearchSlideOffScreenAnimation = @"BlioBookSearchSlideOffScreenAnimation";
static NSString * const BlioBookSearchFadeOffScreenAnimation = @"BlioBookSearchFadeOffScreenAnimation";
static NSString * const BlioBookSearchDisplayFullScreenAnimation = @"BlioBookSearchDisplayFullScreenAnimation";
static NSString * const BlioBookSearchRotateViewInToolbarAnimation = @"BlioBookSearchRotateViewInToolbarAnimation";
static NSString * const BlioBookSearchCollapseViewToToolbarAnimation = @"BlioBookSearchCollapseViewToToolbarAnimation";

@interface BlioBookSearchResults : NSObject {
    NSString *prefix;
    NSString *match;
    NSString *suffix;
    BlioBookmarkRange *bookmarkRange;
}

@property (nonatomic, retain) NSString *prefix;
@property (nonatomic, retain) NSString *match;
@property (nonatomic, retain) NSString *suffix;
@property (nonatomic, retain) BlioBookmarkRange *bookmarkRange;
@end

typedef enum {
    kBlioBookSearchStatusIdle = 0,
    kBlioBookSearchStatusInProgress = 1,
    kBlioBookSearchStatusInProgressHasWrapped = 2,
    kBlioBookSearchStatusComplete = 3,
    kBlioBookSearchStatusStopped = 4
} BlioBookSearchStatus;

@interface BlioBookSearchStatusView : UIView {
    UILabel *statusLabel;
    UILabel *matchesLabel;
    UIActivityIndicatorView *activityView;
    BlioBookSearchStatus status;
    id target;
    SEL action;
}

@property (nonatomic, retain) UILabel *statusLabel;
@property (nonatomic, retain) UILabel *matchesLabel;
@property (nonatomic, retain) UIActivityIndicatorView *activityView;
@property (nonatomic, readonly) BlioBookSearchStatus status;
@property (nonatomic, retain) id target;
@property (nonatomic, assign) SEL action;

- (void)setStatus:(BlioBookSearchStatus)newStatus matches:(NSUInteger)matches;

@end

@interface BlioBookSearchViewController()

@property (nonatomic, assign) UINavigationController *navController;
@property (nonatomic, assign) BOOL searchActive;
@property (nonatomic, retain) UIView *dimmingView;
@property (nonatomic, retain) BlioBookSearchStatusView *statusView;

- (CGRect)rotatedScreenRectWithOrientation:(UIInterfaceOrientation)orientation;
- (CGRect)fullScreenRect;
- (void)displayInToolbar:(BOOL)animated;
- (void)displayFullScreen:(BOOL)animated becomeActive:(BOOL)becomeActive;
- (void)displayOffScreen:(BOOL)animated removedOnCompletion:(BOOL)remove;
- (void)fadeOffScreen:(BOOL)animated removedOnCompletion:(BOOL)remove;
- (void)slideOffScreen:(BOOL)animated removedOnCompletion:(BOOL)remove;
- (void)displayStatusBarWithStyle:(UIStatusBarStyle)barStyle animated:(BOOL)animated;
- (void)hideToolbarsAndView;
- (void)showToolbarsAndView;
- (void)dismissSearchToolbarAnimated:(BOOL)animated;
- (void)highlightCurrentSearchResult;
- (void)setSearchStatus:(BlioBookSearchStatus)newStatus;
- (void)refreshAccessibility;

@end

@implementation BlioBookSearchViewController

@synthesize tableView, dimmingView, toolbar, statusView;
@synthesize bookSearchController, searchController;
@synthesize searchResults, savedSearchTerm;
@synthesize noResultsLabel, noResultsMessage;
@synthesize tintColor, navController;
@synthesize toolbarHidden, searchActive;
@synthesize bookView;

- (void)dealloc {
    self.tableView = nil;
    self.dimmingView = nil;
    self.toolbar = nil;
    self.bookSearchController = nil;
    self.searchController = nil;
    self.searchResults = nil;
    self.savedSearchTerm = nil;
    self.noResultsLabel = nil;
    self.noResultsMessage = nil;
    self.navController = nil;
    self.bookView = nil;
    self.statusView = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark Initialization


- (id)init {
    if ((self = [super init])) {
        BlioBookSearchToolbar *aSearchToolbar = [[BlioBookSearchToolbar alloc] init];
        [aSearchToolbar setDelegate:self];
        [aSearchToolbar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        self.toolbar = aSearchToolbar;
        [aSearchToolbar release];
        
        self.searchResults = [NSMutableArray array];
        currentSearchResult = -1;
        
        resultsInterval = [[UIDevice currentDevice] blioDeviceSearchInterval];
    }
    return self;
}

#pragma mark -
#pragma mark Toolbar

- (BOOL)isToolbarHidden {
    return [self.toolbar isHidden];
}

- (void)setToolbarHidden:(BOOL)hidden {
    [self.toolbar setHidden:hidden];
}

#pragma mark -
#pragma mark View lifecycle

- (void)loadView {
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    UIView *container = [[UIView alloc] initWithFrame:appFrame];
    container.backgroundColor = [UIColor clearColor];
    container.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = container;
    [container release];
    
    [self.toolbar setFrame:CGRectMake(0, 0, CGRectGetWidth(appFrame), 44)];
    [self.view addSubview:self.toolbar];
    
    UITableView *aTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.toolbar.frame), CGRectGetWidth(appFrame), CGRectGetHeight(appFrame) - CGRectGetMaxY(self.toolbar.frame)) style:UITableViewStylePlain];
    [aTableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [aTableView setDataSource:self];
    [aTableView setDelegate:self];
    [self.view addSubview:aTableView];
    self.tableView = aTableView;
    [aTableView release];
    
    UIView *aDimmingView = [[UIView alloc] initWithFrame:aTableView.frame];
    [aDimmingView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [aDimmingView setBackgroundColor:[UIColor colorWithHue:0 saturation:0 brightness:0.2f alpha:1]];
    [aDimmingView setAlpha:0];
    [self.view addSubview:aDimmingView];
    self.dimmingView = aDimmingView;
    [aDimmingView release];
    
    BlioBookSearchStatusView *aStatusView = [[BlioBookSearchStatusView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(aTableView.frame), self.tableView.rowHeight * 1.5f)];
    [aStatusView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [aStatusView setStatus:kBlioBookSearchStatusIdle matches:0];
    [aStatusView setBackgroundColor:[UIColor colorWithHue:0 saturation:0 brightness:0.9f alpha:1]];
    [aStatusView setTarget:self];
    [aStatusView setAction:@selector(continueSearching)];
    [self.tableView setTableFooterView:aStatusView];
    self.statusView = aStatusView;
    [aStatusView release];
    
    [self.view.layer setZPosition:100];
}

- (void)highlightCurrentSearchResult {
    if (currentSearchResult >= [self.searchResults count]) {
        currentSearchResult = 0;
    } else if (currentSearchResult < 0) {
        currentSearchResult = [self.searchResults count] - 1;
    }
    
    BlioBookmarkRange *searchBookmarkRange = [[self.searchResults objectAtIndex:currentSearchResult] bookmarkRange];
    if ([self.bookView respondsToSelector:@selector(highlightWordsInBookmarkRange:animated:)]) {
        [self.bookView highlightWordsInBookmarkRange:searchBookmarkRange animated:NO];
    }
}

- (void)nextResult {
    currentSearchResult++;
    [self highlightCurrentSearchResult];
}

- (void)previousResult {
    currentSearchResult--;
    [self highlightCurrentSearchResult];
}

- (void)dismissSearchToolbar:(id)sender { 
    [self dismissSearchToolbarAnimated:YES];
}

- (void)dismissSearchToolbarAnimated:(BOOL)animated {
    [self.bookSearchController cancel];
    [self.toolbar.searchBar resignFirstResponder];
    self.searchActive = NO;
    [self setSearchStatus:kBlioBookSearchStatusStopped];
        
    if ([self.toolbar inlineMode]) {
        [self fadeOffScreen:animated removedOnCompletion:YES];
    } else {
        [self.navController.toolbar setAlpha:1];
        [self displayOffScreen:animated removedOnCompletion:YES];
    }
    [(id)[(BlioBookViewController *)self.navController.topViewController bookView] highlightWordAtBookmarkPoint:nil];
}

- (void)setTintColor:(UIColor *)newTintColor {
    [newTintColor retain];
    [tintColor release];
    tintColor = newTintColor;
    [self.toolbar setTintColor:tintColor];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (self.toolbar.inlineMode) {
        CGRect rotatedScreen = [self rotatedScreenRectWithOrientation:toInterfaceOrientation];
        CGRect collapsedFrame = rotatedScreen;
        collapsedFrame.origin.y += rotatedScreen.size.height - CGRectGetHeight(self.toolbar.frame);
            
        CGRect offsetFrame = self.view.frame;
        offsetFrame.origin.y = collapsedFrame.origin.y;
            
        [UIView beginAnimations:BlioBookSearchRotateViewInToolbarAnimation context:nil];
        [UIView setAnimationDuration:duration];
        [self.view setFrame:offsetFrame];
        [UIView commitAnimations];      
    } else {
        // Hide the toolbar during a rotation to prevent it animating in front of the search controller
        [self.navController.navigationBar setAlpha:0];
        [self.navController.toolbar setAlpha:0];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (self.toolbar.inlineMode) {
    } else {
        [self.navController.navigationBar setAlpha:1];
        [self.navController.toolbar setAlpha:1];
    }
}

- (void)showInController:(UINavigationController *)controller animated:(BOOL)animated {
    self.searchActive = YES;
    self.toolbar.inlineMode = NO;
    self.navController = controller;
    [self.view setFrame:[self fullScreenRect]];    
    [self.navController.toolbar.superview addSubview:self.view];
    if ([self.searchResults count]) {
        [self displayFullScreen:animated becomeActive:NO];
    } else {
        [self displayFullScreen:animated becomeActive:YES];
    }
}

- (void)removeFromControllerAnimated:(BOOL)animated {
    [self.bookSearchController cancel];
    [self.toolbar.searchBar resignFirstResponder];
    self.searchActive = NO;
    
    if ([self.toolbar inlineMode]) {
        [self slideOffScreen:animated removedOnCompletion:YES];
    } else {
        [self.navController.toolbar setAlpha:1];
        [self displayOffScreen:animated removedOnCompletion:YES];
    }
    
}

- (CGRect)rotatedScreenRectWithOrientation:(UIInterfaceOrientation)orientation {
    CGRect appFrame = [[UIScreen mainScreen] bounds];
    CGAffineTransform screenTransform = self.navController.view.transform;
    CGRect statusBarBounds = CGRectApplyAffineTransform([[UIApplication sharedApplication] statusBarFrame], screenTransform);
    CGFloat statusBarHeight = CGRectGetHeight(statusBarBounds);
    CGRect fullScreen;
    
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        fullScreen = CGRectMake(0, statusBarHeight, appFrame.size.width, appFrame.size.height - statusBarHeight);
    } else {
        fullScreen = CGRectMake(0, statusBarHeight, appFrame.size.height, appFrame.size.width - statusBarHeight);
    }

    return fullScreen;
}
    
- (CGRect)fullScreenRect {
    return [self rotatedScreenRectWithOrientation:self.navController.interfaceOrientation];
}

#pragma mark -
#pragma mark Search Status
- (void)setSearchStatus:(BlioBookSearchStatus)newStatus {
    
    // Show/hide the dim view
    switch (newStatus) {
        case kBlioBookSearchStatusIdle:
            [self.dimmingView setAlpha:1];
            break;
        default:
            [self.dimmingView setAlpha:0];
            break;
    }
    
    [self.statusView setStatus:newStatus matches:[self.searchResults count]];
        
}

- (void)continueSearching {
    BlioBookSearchStatus status = self.statusView.status;
    if ((status == kBlioBookSearchStatusIdle) || (status == kBlioBookSearchStatusStopped)) {
        [self.bookSearchController findNextOccurrence];
        if (self.bookSearchController.hasWrapped) {
            [self setSearchStatus:kBlioBookSearchStatusInProgressHasWrapped];
        } else {
            [self setSearchStatus:kBlioBookSearchStatusInProgress];
        }
    }    
}

- (void)refreshAccessibility {
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

#pragma mark -
#pragma mark Animations

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    if ([animationID isEqualToString:BlioBookSearchDisplayOffScreenAnimation]) {
        [self.view removeFromSuperview];
        [self.toolbar setTintColor:self.tintColor];
        [self.toolbar setBarStyle:UIBarStyleDefault];
    } else if ([animationID isEqualToString:BlioBookSearchFadeOffScreenAnimation]) {
        [self.view removeFromSuperview];
        [self.view setAlpha:1];
        [self.toolbar setTintColor:self.tintColor];
        [self.toolbar setBarStyle:UIBarStyleDefault];
    } else if ([animationID isEqualToString:BlioBookSearchSlideOffScreenAnimation]) {
        [self.view removeFromSuperview];
        [self.view setAlpha:1];
        [self.toolbar setTintColor:self.tintColor];
        [self.toolbar setBarStyle:UIBarStyleDefault];
    } else if ([animationID isEqualToString:BlioBookSearchDisplayFullScreenAnimation]) {
        [self.toolbar.searchBar becomeFirstResponder];
    }
    
    [self refreshAccessibility];
    
}

- (void)displayInToolbar:(BOOL)animated {  
    
    [self displayStatusBarWithStyle:UIStatusBarStyleBlackTranslucent animated:NO];
    [self.navController.toolbar setAlpha:0];
    [self showToolbarsAndView];
    
    CGRect fullScreen = [self fullScreenRect];
    CGRect collapsedFrame = fullScreen;
    collapsedFrame.origin.y += fullScreen.size.height - CGRectGetHeight(self.toolbar.frame);
    
    if (!CGRectEqualToRect(self.view.frame, collapsedFrame)) {
        
        if (animated) {
            [UIView beginAnimations:BlioBookSearchCollapseViewToToolbarAnimation context:nil];
            [UIView setAnimationDuration:0.35];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        }
        
        [self.view setFrame:collapsedFrame];
        [self.toolbar setTintColor:self.navController.toolbar.tintColor];
        [self.toolbar setBarStyle:self.navController.toolbar.barStyle];
        [self.toolbar setInlineMode:YES];
        
        if (animated) {
            [UIView commitAnimations];
        }
    }
}

- (void)displayFullScreen:(BOOL)animated becomeActive:(BOOL)becomeActive {
    
    [self displayStatusBarWithStyle:UIStatusBarStyleDefault animated:animated];
    
    CGRect fullScreen = [self fullScreenRect];
    
    if (animated) {
        [UIView beginAnimations:BlioBookSearchDisplayFullScreenAnimation context:nil];
        [UIView setAnimationDuration:0.35];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        if (becomeActive) {
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        }
        CGRect offscreen = fullScreen;
        offscreen.origin.y += fullScreen.size.height;
        [self.view setFrame:offscreen];
        [self performSelector:@selector(hideToolbarsAndView) withObject:nil afterDelay:0.4f];
    }
    
    [self.view setFrame:fullScreen];
    [self.toolbar setTintColor:self.tintColor];
    [self.toolbar setBarStyle:UIBarStyleDefault];
    if (self.toolbar.inlineMode) {
        [self.toolbar setInlineMode:NO];
    }
    
    if (!animated && becomeActive) {
        [self.toolbar.searchBar becomeFirstResponder];
    }
    
    if (animated) {
        [UIView commitAnimations];
    } else {
        [self hideToolbarsAndView];
    }
}

- (void)fadeOffScreen:(BOOL)animated removedOnCompletion:(BOOL)remove {
    [self displayStatusBarWithStyle:UIStatusBarStyleBlackTranslucent animated:NO];
    
    [self showToolbarsAndView];
    [self.navController.toolbar setAlpha:0];
    
    if (animated) {
        [UIView beginAnimations:BlioBookSearchFadeOffScreenAnimation context:nil];
        [UIView setAnimationDuration:0.35];
        if (remove) {
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        }
    }
        
    if (!animated && remove) {
        [self.view removeFromSuperview];
    } else {
        [self.view setAlpha:0];
    }
    
    [self.navController.toolbar setAlpha:1];
    
    if (animated) {
        [UIView commitAnimations];
    }
}

- (void)slideOffScreen:(BOOL)animated removedOnCompletion:(BOOL)remove {
    [self displayStatusBarWithStyle:UIStatusBarStyleBlackTranslucent animated:NO];
    
    [self.navController setToolbarHidden:NO];
    [self.navController.toolbar setAlpha:0];
    CGRect onScreen = self.view.frame;
    CGRect offScreen = onScreen;
    offScreen.origin.x += offScreen.size.width;
    
    if (animated) {
        [UIView beginAnimations:BlioBookSearchSlideOffScreenAnimation context:nil];
        [UIView setAnimationDuration:0.35];
        if (remove) {
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        }
    }
    
    if (!animated && remove) {
        [self.view removeFromSuperview];
    } else {
        [self.view setAlpha:0];
        [self.view setFrame:offScreen];
    }
    
    [self.navController.toolbar setAlpha:1];
    
    if (animated) {
        [UIView commitAnimations];
    }
}

- (void)displayOffScreen:(BOOL)animated removedOnCompletion:(BOOL)remove {
    [self displayStatusBarWithStyle:UIStatusBarStyleBlackTranslucent animated:NO];
    
    [self showToolbarsAndView];
    
    CGRect fullScreen = [self fullScreenRect];
    CGRect collapsedFrame = fullScreen;
    collapsedFrame.origin.y += fullScreen.size.height;
    
    if (!CGRectEqualToRect(self.view.frame, collapsedFrame)) {
        
        if (animated) {
            [UIView beginAnimations:BlioBookSearchDisplayOffScreenAnimation context:nil];
            [UIView setAnimationDuration:0.35];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
            if (remove) {
                [UIView setAnimationDelegate:self];
                [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
            }
        }
        
        if (!animated && remove) {
            [self.view removeFromSuperview];
        } else {
            [self.view setFrame:collapsedFrame];
        }
        
        if (animated) {
            [UIView commitAnimations];
        }

    }    
}

- (void)displayStatusBarWithStyle:(UIStatusBarStyle)barStyle animated:(BOOL)animated {
    UIApplication *application = [UIApplication sharedApplication];
    
    [application setStatusBarStyle:barStyle animated:animated];
    
    if ([application respondsToSelector:@selector(setStatusBarHidden:withAnimation:)]) 
        [application setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    else
        [(id)application setStatusBarHidden:NO animated:animated]; // typecast as id to mask deprecation warnings.
}

- (void)hideToolbarsAndView {
    [self.navController setNavigationBarHidden:YES];
    [self.navController setToolbarHidden:YES];
    [[[self.navController topViewController] view] setHidden:YES];
    [self refreshAccessibility];
}

- (void)showToolbarsAndView {
    [self.navController setNavigationBarHidden:NO];
    [self.navController setToolbarHidden:NO];
    [[[self.navController topViewController] view] setHidden:NO];
    [self refreshAccessibility];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.searchResults count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        UIView *aBackgroundView = [[UIView alloc] init];
        aBackgroundView.backgroundColor = [UIColor whiteColor];
        cell.backgroundView = aBackgroundView;
        [aBackgroundView release];
        
        UILabel *page = [[UILabel alloc] init];
        page.font = [UIFont systemFontOfSize:17];
        page.adjustsFontSizeToFitWidth = YES;
        page.textColor = [UIColor darkGrayColor];
        page.textAlignment = UITextAlignmentRight;
        page.tag = BLIOBOOKSEARCHCELLPAGETAG;
        [page setIsAccessibilityElement:NO];
        [cell.contentView addSubview:page];
        [page release];
        
        UILabel *prefix = [[UILabel alloc] init];
        prefix.font = [UIFont systemFontOfSize:17];
        prefix.tag = BLIOBOOKSEARCHCELLPREFIXTAG;
        [prefix setIsAccessibilityElement:NO];
        [cell.contentView addSubview:prefix];
        [prefix release];
        
        UILabel *match = [[UILabel alloc] init];
        match.font = [UIFont boldSystemFontOfSize:17];
        match.tag = BLIOBOOKSEARCHCELLMATCHTAG;
        [match setIsAccessibilityElement:NO];
        [cell.contentView addSubview:match];
        [match release];
        
        UILabel *suffix = [[UILabel alloc] init];
        suffix.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        suffix.font = [UIFont systemFontOfSize:17];
        suffix.tag = BLIOBOOKSEARCHCELLSUFFIXTAG;
        [suffix setIsAccessibilityElement:NO];
        [cell.contentView addSubview:suffix];
        [suffix release];
    }
    
    // Configure the cell...
    BlioBookSearchResults *result = [self.searchResults objectAtIndex:[indexPath row]];
    
    UILabel *page = (UILabel *)[cell.contentView viewWithTag:BLIOBOOKSEARCHCELLPAGETAG];
    NSString *pageNumberText;
    if (self.bookView) {
        NSInteger pageNum = [self.bookView pageNumberForBookmarkPoint:result.bookmarkRange.startPoint];
        pageNumberText = [[self.bookView contentsDataSource] displayPageNumberForPageNumber:pageNum];
        
    } else {
        pageNumberText = [NSString stringWithFormat:@"%d", result.bookmarkRange.startPoint.layoutPage];
    }
    page.text = [NSString stringWithFormat:@"p.%@", pageNumberText];
    [page sizeToFit];
    CGRect pageFrame = page.frame;
    pageFrame.origin = CGPointMake(5, (CGRectGetHeight(cell.contentView.frame) - pageFrame.size.height)/2.0f);
    pageFrame.size.width = 50;
    page.frame = pageFrame;
    
    UILabel *prefix = (UILabel *)[cell.contentView viewWithTag:BLIOBOOKSEARCHCELLPREFIXTAG];
    prefix.text = result.prefix;
    [prefix sizeToFit];
    CGRect prefixFrame = prefix.frame;
    prefixFrame.origin = CGPointMake(CGRectGetMaxX(pageFrame) + 10, (CGRectGetHeight(cell.contentView.frame) - prefixFrame.size.height)/2.0f);
    prefix.frame = prefixFrame;
    //prefix.backgroundColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.3];
    
    UILabel *match = (UILabel *)[cell.contentView viewWithTag:BLIOBOOKSEARCHCELLMATCHTAG];
    match.text = result.match;
    [match sizeToFit];
    CGRect matchFrame = match.frame;
    matchFrame.origin = CGPointMake(CGRectGetMaxX(prefixFrame), (CGRectGetHeight(cell.contentView.frame) - matchFrame.size.height)/2.0f);
    match.frame = matchFrame;
    //match.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.3];
    
    UILabel *suffix = (UILabel *)[cell.contentView viewWithTag:BLIOBOOKSEARCHCELLSUFFIXTAG];
    suffix.text = result.suffix;
    [suffix sizeToFit];
    suffix.frame = CGRectMake(CGRectGetMaxX(matchFrame), (CGRectGetHeight(cell.contentView.frame) - suffix.frame.size.height)/2.0f, CGRectGetWidth(cell.contentView.frame) - CGRectGetMaxX(matchFrame) - 10, suffix.frame.size.height);
    //suffix.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.3];
    
    [cell setAccessibilityLabel:[NSString stringWithFormat:NSLocalizedString(@"Match %d, page %@, %@%@%@", @"Book Search results cell accessibility label string format"), [indexPath row] + 1, pageNumberText, result.prefix, result.match, result.suffix]];
    [cell setAccessibilityHint:[NSString stringWithFormat:NSLocalizedString(@"Jumps to search match on page %@.", @"Book Search results cell accessibility hint string format"), pageNumberText]];

     return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.toolbar.searchBar resignFirstResponder];
    currentSearchResult = [indexPath row];
    [self highlightCurrentSearchResult];
    [self displayInToolbar:YES];
}

#pragma mark -
#pragma mark BlioBookSearchDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    if ([self.toolbar inlineMode]) {
        if ([[searchBar text] isEqualToString:@""]) {
            // Resign immediately but become active in the animation completion
            [self displayFullScreen:YES becomeActive:YES];
            [self.toolbar.searchBar resignFirstResponder];
        } else {
            [self displayFullScreen:YES becomeActive:NO];
            [self.toolbar.searchBar resignFirstResponder];
        }
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self.toolbar.searchBar resignFirstResponder];
    
    if ([self.statusView status] == kBlioBookSearchStatusIdle) {
        if ([searchBar.text length] > 0) {
            BlioBookmarkPoint *currentBookmarkPoint = self.bookView.currentBookmarkPoint;
            [self setSearchStatus:kBlioBookSearchStatusInProgress];
            [self.bookSearchController findString:searchBar.text fromBookmarkPoint:currentBookmarkPoint];
        }
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self.bookSearchController cancel];
    [self.searchResults removeAllObjects];
    currentSearchResult = -1;
    [self.tableView reloadData];
        
    BOOL perCharacterSearch = NO;
    
    if (([searchText length] > 0) && ([[UIDevice currentDevice] blioDevicePerCharacterSearchEnabled])) {
        perCharacterSearch = YES;
        if (UIAccessibilityIsVoiceOverRunning != nil) {
            if (UIAccessibilityIsVoiceOverRunning()) {
                perCharacterSearch = NO;
            }
        }
    }
    
    if (perCharacterSearch) {
        BlioBookmarkPoint *currentBookmarkPoint = self.bookView.currentBookmarkPoint;
        [self setSearchStatus:kBlioBookSearchStatusInProgress];
        [self.bookSearchController findString:searchText fromBookmarkPoint:currentBookmarkPoint];
    } else {
        [self setSearchStatus:kBlioBookSearchStatusIdle];
    }

}

#pragma mark -
#pragma mark BlioBookSearchDelegate

- (void)searchController:(BlioBookSearchController *)aSearchController didFindString:(NSString *)searchString atBookmarkRange:(BlioBookmarkRange *)bookmarkRange withPrefix:(NSString *)prefix withSuffix:(NSString *)suffix {
    
    BlioBookSearchResults *result = [[BlioBookSearchResults alloc] init];
    result.prefix = prefix;
    result.match  = searchString;
    result.suffix = suffix;
    result.bookmarkRange = bookmarkRange;
    
    [self.searchResults addObject:result];
    [result release];

    NSIndexPath *newRow = [NSIndexPath indexPathForRow:([self.searchResults count] - 1) inSection:0];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newRow] withRowAnimation:UITableViewRowAnimationFade];

    NSUInteger resultsBatch = 100;
    if (UIAccessibilityIsVoiceOverRunning != nil) {
        if (UIAccessibilityIsVoiceOverRunning()) {
            resultsBatch = 10;
        }
    }
    
    if (([self.searchResults count] % resultsBatch) == 0) {
        [self setSearchStatus:kBlioBookSearchStatusStopped];
    } else {
        [aSearchController performSelector:@selector(findNextOccurrence) withObject:nil afterDelay:resultsInterval];
    }    
}

- (void)searchControllerDidReachEndOfBook:(BlioBookSearchController *)aSearchController {
    [self setSearchStatus:kBlioBookSearchStatusInProgressHasWrapped];
    [aSearchController findNextOccurrence];
}

- (void)searchControllerDidCompleteSearch:(BlioBookSearchController *)aSearchController {
    [self setSearchStatus:kBlioBookSearchStatusComplete];
}
    
@end

@implementation BlioBookSearchResults

@synthesize prefix, match, suffix, bookmarkRange;

- (void)dealloc {
    self.prefix = nil;
    self.match = nil;
    self.suffix = nil;
    self.bookmarkRange = nil;
    [super dealloc];
}

@end

@implementation BlioBookSearchStatusView

@synthesize statusLabel, matchesLabel, activityView, status;
@synthesize target, action;

- (void)dealloc {
    self.statusLabel = nil;
    self.matchesLabel = nil;
    self.activityView = nil;
    self.target = nil;
    self.action = nil;
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self == [super initWithFrame:frame])) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        UIActivityIndicatorView *aActivityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        aActivityView.hidesWhenStopped = YES;
        [aActivityView setIsAccessibilityElement:NO];
        [self addSubview:aActivityView];
        self.activityView = aActivityView;
        [aActivityView release];
        
        UILabel *aStatusLabel = [[UILabel alloc] init];
        [aStatusLabel setBackgroundColor:[UIColor clearColor]];
        [aStatusLabel setFont:[UIFont boldSystemFontOfSize:16]];
        [aStatusLabel setIsAccessibilityElement:NO];
        [self addSubview:aStatusLabel];
        self.statusLabel = aStatusLabel;
        [aStatusLabel release];
        
        UILabel *aMatchesLabel = [[UILabel alloc] init];
        [aMatchesLabel setBackgroundColor:[UIColor clearColor]];
        [aMatchesLabel setFont:[UIFont systemFontOfSize:14]];
        [aMatchesLabel setIsAccessibilityElement:NO];
        [self addSubview:aMatchesLabel];
        self.matchesLabel = aMatchesLabel;
        [aMatchesLabel release];
        
        [self setHidden:YES];
    }
    return self;
}

- (void)setStatus:(BlioBookSearchStatus)newStatus matches:(NSUInteger)matches {
    
    if ((newStatus == kBlioBookSearchStatusStopped) && (status == kBlioBookSearchStatusComplete)) {
        return; // Cannot cancel a search that is complete
    }
    
    status = newStatus;
        
    NSString *matchString;
    switch (matches) {
        case 0:
            matchString = NSLocalizedString(@"No matches", @"Book Search No matches");
            break;
        case 1:
            matchString = NSLocalizedString(@"1 match found", @"Book Search 1 match");
            break;
        default:
            matchString = [NSString stringWithFormat:NSLocalizedString(@"%d matches found", @"Book Search greater than 1 matches"), matches];
            break;
    }
    
    switch (status) {
        case kBlioBookSearchStatusInProgress:
            [self.activityView startAnimating];
            [self.statusLabel setText:NSLocalizedString(@"Searching...", @"Book Search search in progress")];
            [self.matchesLabel setText:nil];
            if([[UIDevice currentDevice] compareSystemVersion:@"4.0"] >= NSOrderedSame) {
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Searching.", @"Book Search search in progress accessibility announcement"));
            }
            [self setHidden:NO];
            break;
        case kBlioBookSearchStatusInProgressHasWrapped:
            [self.activityView startAnimating];
            [self.statusLabel setText:NSLocalizedString(@"Search Wrapped...", @"Book Search search in progress, has reached end and is continuing from the start")];
            [self.matchesLabel setText:nil];
            if([[UIDevice currentDevice] compareSystemVersion:@"4.0"] >= NSOrderedSame) {
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Search Wrapped.", @"Book Search search in progress, has wrapped, accessibility announcement"));
            }
            [self setHidden:NO];
            break;
        case kBlioBookSearchStatusComplete:
            [self.activityView stopAnimating];
            [self.statusLabel setText:NSLocalizedString(@"Search Completed", @"Book Search search has completed")];
            [self.matchesLabel setText:matchString];
            if([[UIDevice currentDevice] compareSystemVersion:@"4.0"] >= NSOrderedSame) {
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, [NSString stringWithFormat:NSLocalizedString(@"Search Completed. %@", @"Book Search search has completed, accessibility announcement"), matchString]);
            }
            [self setHidden:NO];
            break;
        case kBlioBookSearchStatusStopped:
            [self.activityView stopAnimating];
            [self.statusLabel setText:NSLocalizedString(@"Load More...", @"Book Search load more results")];
            [self.matchesLabel setText:matchString];
            if([[UIDevice currentDevice] compareSystemVersion:@"4.0"] >= NSOrderedSame) {
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, [NSString stringWithFormat:NSLocalizedString(@"%@", @"Book Search matches found accessibility announcement"), matchString]);                                                                      
            }
            [self setHidden:NO];
            break;
        default:
            [self setHidden:YES];
            break;
    }
    [self setNeedsLayout];
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
}

- (void)layoutSubviews {
    [self.statusLabel sizeToFit];
    [self.matchesLabel sizeToFit];

    CGRect statusLabelFrame = self.statusLabel.frame;
    CGRect matchesLabelFrame = self.matchesLabel.frame;
    CGRect activityFrame = self.activityView.frame;
    CGFloat spacing = 10;
        
    if ([self.activityView isAnimating]) {
        statusLabelFrame.size.width = MIN(CGRectGetWidth(statusLabelFrame), CGRectGetWidth(self.bounds) - CGRectGetWidth(activityFrame) - spacing);
        CGFloat combinedWidth = CGRectGetWidth(activityFrame) + spacing + CGRectGetWidth(statusLabelFrame);
        CGFloat padding = (CGRectGetWidth(self.bounds) - combinedWidth)/2.0f;
        activityFrame.origin.x = floorf(padding);
        activityFrame.origin.y = floorf((CGRectGetHeight(self.bounds) - CGRectGetHeight(activityFrame))/2.0f);
        statusLabelFrame.origin.x = CGRectGetMaxX(activityFrame) + spacing;
    } else {
        statusLabelFrame.size.width = MIN(CGRectGetWidth(statusLabelFrame), CGRectGetWidth(self.bounds));
        CGFloat padding = (CGRectGetWidth(self.bounds) - CGRectGetWidth(statusLabelFrame))/2.0f;
        statusLabelFrame.origin.x = floorf(padding);
    }
    
    matchesLabelFrame.size.width = MIN(CGRectGetWidth(matchesLabelFrame), CGRectGetWidth(self.bounds));
    CGFloat padding = (CGRectGetWidth(self.bounds) - CGRectGetWidth(matchesLabelFrame))/2.0f;
    matchesLabelFrame.origin.x = floorf(padding);
    
    statusLabelFrame.origin.y = floorf((CGRectGetHeight(self.bounds) - (CGRectGetHeight(statusLabelFrame) + CGRectGetHeight(matchesLabelFrame)))/2.0f);
    matchesLabelFrame.origin.y = ceilf(CGRectGetMaxY(statusLabelFrame));

    self.activityView.frame = activityFrame;
    self.statusLabel.frame = statusLabelFrame;
    self.matchesLabel.frame = matchesLabelFrame;    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint point = [[touches anyObject] locationInView:self];
    if ([self pointInside:point withEvent:nil]) {
        if ([self.target respondsToSelector:self.action]) {
            [self.target performSelector:self.action];
        }
    }
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetRGBStrokeColor(ctx, 0.878f, 0.878f, 0.878f, 1);
    CGContextSetLineWidth(ctx, 1);
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, 0, CGRectGetMaxY(rect));
    CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    CGContextStrokePath(ctx);
}

- (BOOL)isAccessibilityElement {
    return YES;
}

- (NSString *)accessibilityLabel {
    NSString *label = nil;
    
    switch (self.status) {
        case kBlioBookSearchStatusInProgress:
            label = NSLocalizedString(@"Searching.", @"Book Search search in progress accessibility announcement");
            break;
        case kBlioBookSearchStatusInProgressHasWrapped:
            label = NSLocalizedString(@"Search Wrapped.", @"Book Search search in progress, has wrapped, accessibility announcement");
            break;
        case kBlioBookSearchStatusComplete:
            label = [NSString stringWithFormat:NSLocalizedString(@"Search Completed. %@", @"Book Search search has completed, accessibility announcement"), self.matchesLabel.text];
            break;
        case kBlioBookSearchStatusStopped:
            label = [NSString stringWithFormat:NSLocalizedString(@"%@", @"Book Search matches found accessibility announcement"), self.matchesLabel.text];                                                                      
            break;
        default:
            break;
    }
    
    return label;
}

- (NSString *)accessibilityHint {
    NSString *hint = nil;
    
    switch (self.status) {
        case kBlioBookSearchStatusStopped:
            hint = NSLocalizedString(@"Continues searching.", @"Book Search load more search results accessibility hint");                                                                      
            break;
        default:
            break;
    }
            
    return hint;
}

- (UIAccessibilityTraits)accessibilityTraits {
    
    UIAccessibilityTraits traits = 0;
    
    switch (self.status) {
        case kBlioBookSearchStatusStopped:
            traits = UIAccessibilityTraitButton;                                                                      
            break;
        default:
            traits = UIAccessibilityTraitStaticText; 
            break;
    }
    
    return traits;
}

@end
