//
//  BlioBookSearchViewController.m
//  BlioApp
//
//  Created by matt on 07/06/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "BlioBookSearchViewController.h"
#import <libEucalyptus/EucBookContentsTableViewController.h>
#import "BlioBookSearchResultsTableViewController.h"
#import "BlioBookSearchResult.h"
#import "UIDevice+BlioAdditions.h"
#import <libEucalyptus/THUIDeviceAdditions.h>

#define RESULTSPREFIXSTRINGMAXLENGTH 15

static NSString * const BlioBookSearchDisplayOffScreenAnimation = @"BlioBookSearchDisplayOffScreenAnimation";
static NSString * const BlioBookSearchSlideOffScreenAnimation = @"BlioBookSearchSlideOffScreenAnimation";
static NSString * const BlioBookSearchFadeOffScreenAnimation = @"BlioBookSearchFadeOffScreenAnimation";
static NSString * const BlioBookSearchDisplayFullScreenAnimation = @"BlioBookSearchDisplayFullScreenAnimation";
static NSString * const BlioBookSearchRotateViewInToolbarAnimation = @"BlioBookSearchRotateViewInToolbarAnimation";
static NSString * const BlioBookSearchCollapseViewToToolbarAnimation = @"BlioBookSearchCollapseViewToToolbarAnimation";

@interface BlioBookSearchViewController()

@property (nonatomic, retain) BlioBookSearchResultsTableViewController *resultsController;
@property (nonatomic, assign) UINavigationController *navController;

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

@synthesize resultsController;
@synthesize toolbar;
@synthesize bookSearchController;
@synthesize tintColor, navController;
@synthesize toolbarHidden;
@synthesize bookView;

- (void)dealloc {
    self.resultsController = nil;
    self.toolbar = nil;
    self.bookSearchController = nil;
    self.navController = nil;
    self.bookView = nil;
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
        
        BlioBookSearchResultsTableViewController *aResultsController = [[BlioBookSearchResultsTableViewController alloc] initWithStyle:UITableViewStylePlain];
        aResultsController.resultsDelegate = self;
        self.resultsController = aResultsController;
        [aResultsController release];
        
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
    
    [self.resultsController.view setFrame:CGRectMake(0, CGRectGetMaxY(self.toolbar.frame), CGRectGetWidth(appFrame), CGRectGetHeight(appFrame) - CGRectGetMaxY(self.toolbar.frame))];
    [self.view addSubview:self.resultsController.view];
    
    [self.view.layer setZPosition:100];
}

- (void)highlightCurrentSearchResult {
    if (currentSearchResult >= [self.resultsController.searchResults count]) {
        currentSearchResult = 0;
    } else if (currentSearchResult < 0) {
        currentSearchResult = [self.resultsController.searchResults count] - 1;
    }
    
    BlioBookmarkRange *searchBookmarkRange = [[self.resultsController.searchResults objectAtIndex:currentSearchResult] bookmarkRange];
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
    [self setSearchStatus:kBlioBookSearchStatusStopped];
        
    if ([self.toolbar inlineMode]) {
        [self fadeOffScreen:animated removedOnCompletion:YES];
    } else {
        [self.navController.toolbar setAlpha:1];
        [self displayOffScreen:animated removedOnCompletion:YES];
    }
    
    if ([self.bookView respondsToSelector:@selector(highlightWordAtBookmarkPoint:)]) {
        [self.bookView highlightWordAtBookmarkPoint:nil];
    }
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
    self.toolbar.inlineMode = NO;
    self.navController = controller;
    [self.view setFrame:[self fullScreenRect]];    
    [self.navController.toolbar.superview addSubview:self.view];
    if ([self.resultsController.searchResults count]) {
        [self displayFullScreen:animated becomeActive:NO];
    } else {
        [self displayFullScreen:animated becomeActive:YES];
    }
}

- (void)removeFromControllerAnimated:(BOOL)animated {
    [self.bookSearchController cancel];
    [self.toolbar.searchBar resignFirstResponder];
    
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

- (void)setSearchStatus:(BlioBookSearchStatus)newStatus {
    searchStatus = newStatus;
    [self.resultsController setSearchStatus:newStatus];
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
#pragma mark Results Controller delegate

- (void)resultsController:(BlioBookSearchResultsTableViewController *)resultsController didSelectResultAtIndex:(NSUInteger)index {
    [self.toolbar.searchBar resignFirstResponder];
    currentSearchResult = index;
    [self highlightCurrentSearchResult];
    [self displayInToolbar:YES];
}

- (void)resultsControllerDidContinueSearch:(BlioBookSearchResultsTableViewController *)resultsController {
    if ((searchStatus == kBlioBookSearchStatusIdle) || (searchStatus == kBlioBookSearchStatusStopped)) {
        [self.bookSearchController findNextOccurrence];
        if (self.bookSearchController.hasWrapped) {
            [self setSearchStatus:kBlioBookSearchStatusInProgressHasWrapped];
        } else {
            [self setSearchStatus:kBlioBookSearchStatusInProgress];
        }
    }    
}

#pragma mark -
#pragma mark Results Controller Formatter

- (NSString *)displayPageNumberForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint {
    NSInteger pageNum = [self.bookView pageNumberForBookmarkPoint:bookmarkPoint];
    return [[self.bookView contentsDataSource] displayPageNumberForPageNumber:pageNum];
}

#pragma mark -
#pragma mark BlioBookSearchDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    if ([self.toolbar inlineMode]) {
        if ([self isSearchActive]) {
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
    
    if (searchStatus == kBlioBookSearchStatusIdle) {
        if ([searchBar.text length] > 0) {
            BlioBookmarkPoint *currentBookmarkPoint = self.bookView.currentBookmarkPoint;
            [self setSearchStatus:kBlioBookSearchStatusInProgress];
            BOOL success = [self.bookSearchController findString:searchBar.text fromBookmarkPoint:currentBookmarkPoint];
            if (!success) {
                [self setSearchStatus:kBlioBookSearchStatusIdle];
            }
        }
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self.bookSearchController cancel];
    [self.resultsController.searchResults removeAllObjects];
    [self.resultsController.tableView reloadData];
    currentSearchResult = -1;
        
    BOOL perCharacterSearch = NO;
    
    if (([searchText length] > 2) && ([[UIDevice currentDevice] blioDevicePerCharacterSearchEnabled])) {
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
        BOOL success = [self.bookSearchController findString:searchText fromBookmarkPoint:currentBookmarkPoint];
        if (!success) {
            [self setSearchStatus:kBlioBookSearchStatusIdle];
        }
    } else {
        [self setSearchStatus:kBlioBookSearchStatusIdle];
    }

}

#pragma mark -
#pragma mark BlioBookSearchDelegate

- (void)searchController:(BlioBookSearchController *)aSearchController didFindString:(NSString *)searchString atBookmarkRange:(BlioBookmarkRange *)bookmarkRange withPrefix:(NSString *)prefix withSuffix:(NSString *)suffix {
    
    BlioBookSearchResult *result = [[BlioBookSearchResult alloc] init];
    result.prefix = prefix;
    result.match  = searchString;
    result.suffix = suffix;
    result.bookmarkRange = bookmarkRange;
    
    [self.resultsController addResult:result];
    [result release];

    NSUInteger resultsBatch = 100;
    if (UIAccessibilityIsVoiceOverRunning != nil) {
        if (UIAccessibilityIsVoiceOverRunning()) {
            resultsBatch = 10;
        }
    }
    
    if (([self.resultsController.searchResults count] % resultsBatch) == 0) {
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

- (BOOL)isSearchActive {
    BOOL active;
    
    switch (searchStatus) {
        case kBlioBookSearchStatusInProgress:
        case kBlioBookSearchStatusInProgressHasWrapped:
            active = YES;
            break;
        default:
            active = NO;
            break;
    }
    return active;
}
    
@end
