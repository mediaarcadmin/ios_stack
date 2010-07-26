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

#define BLIOBOOKSEARCHCELLPAGETAG 1233
#define BLIOBOOKSEARCHCELLPREFIXTAG 1234
#define BLIOBOOKSEARCHCELLMATCHTAG 1235
#define BLIOBOOKSEARCHCELLSUFFIXTAG 1236

#define RESULTSPREFIXSTRINGMAXLENGTH 15

static NSString * const BlioBookSearchDisplayOffScreenAnimation = @"BlioBookSearchDisplayOffScreenAnimation";
static NSString * const BlioBookSearchSlideOffScreenAnimation = @"BlioBookSearchSlideOffScreenAnimation";
static NSString * const BlioBookSearchFadeOffScreenAnimation = @"BlioBookSearchFadeOffScreenAnimation";
static NSString * const BlioBookSearchDisplayFullScreenAnimation = @"BlioBookSearchDisplayFullScreenAnimation";

@interface BlioBookSearchResults : NSObject {
    NSString *prefix;
    NSString *match;
    NSString *suffix;
    BlioBookmarkPoint *bookmark;
}

@property (nonatomic, retain) NSString *prefix;
@property (nonatomic, retain) NSString *match;
@property (nonatomic, retain) NSString *suffix;
@property (nonatomic, retain) BlioBookmarkPoint *bookmark;
@end

@interface BlioBookSearchViewController()

@property (nonatomic, assign) UINavigationController *navController;
@property (nonatomic, assign) BOOL searchActive;

- (CGRect)rotatedScreenRectWithOrientation:(UIInterfaceOrientation)orientation;
- (CGRect)fullScreenRect;
- (void)displayInToolbar:(BOOL)animated;
- (void)displayFullScreen:(BOOL)animated becomeActive:(BOOL)becomeActive;
- (void)displayOffScreen:(BOOL)animated removedOnCompletion:(BOOL)remove;
- (void)fadeOffScreen:(BOOL)animated removedOnCompletion:(BOOL)remove;
- (void)slideOffScreen:(BOOL)animated removedOnCompletion:(BOOL)remove;
- (void)displayStatusBarWithStyle:(UIStatusBarStyle)barStyle animated:(BOOL)animated;
- (void)dismissSearchToolbarAnimated:(BOOL)animated;
- (void)highlightCurrentSearchResult;

@end

@implementation BlioBookSearchViewController

@synthesize tableView, toolbar;
@synthesize bookSearchController, searchController;
@synthesize searchResults, savedSearchTerm;
@synthesize noResultsLabel, noResultsMessage;
@synthesize tintColor, navController;
@synthesize toolbarHidden, searchActive;
@synthesize bookView;

- (void)dealloc {
    self.tableView = nil;
    self.toolbar = nil;
    self.bookSearchController = nil;
    self.searchController = nil;
    self.searchResults = nil;
    self.savedSearchTerm = nil;
    self.noResultsLabel = nil;
    self.noResultsMessage = nil;
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
        
        self.searchResults = [NSMutableArray array];
        currentSearchResult = -1;
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
    [aTableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [aTableView setDataSource:self];
    [aTableView setDelegate:self];
    [self.view addSubview:aTableView];
    self.tableView = aTableView;
    [aTableView release];
}

- (void)highlightCurrentSearchResult {
    if (currentSearchResult >= [self.searchResults count]) {
        currentSearchResult = 0;
    } else if (currentSearchResult < 0) {
        currentSearchResult = [self.searchResults count] - 1;
    }
    
    BlioBookmarkPoint *searchBookmarkPoint = [[self.searchResults objectAtIndex:currentSearchResult] bookmark];
    [(id)[(BlioBookViewController *)self.navController.topViewController bookView] goToBookmarkPoint:searchBookmarkPoint animated:NO];
    [(id)[(BlioBookViewController *)self.navController.topViewController bookView] highlightWordAtBookmarkPoint:searchBookmarkPoint];
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
            
        [UIView beginAnimations:@"rotateViewInToolbar" context:nil];
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
}

- (void)displayInToolbar:(BOOL)animated {  
    
    [self displayStatusBarWithStyle:UIStatusBarStyleBlackTranslucent animated:NO];
    [self.navController.toolbar setAlpha:0];
    
    CGRect fullScreen = [self fullScreenRect];
    CGRect collapsedFrame = fullScreen;
    collapsedFrame.origin.y += fullScreen.size.height - CGRectGetHeight(self.toolbar.frame);
    
    if (!CGRectEqualToRect(self.view.frame, collapsedFrame)) {
        
        if (animated) {
            [UIView beginAnimations:@"collapseViewToToolbar" context:nil];
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
    }    
}

- (void)fadeOffScreen:(BOOL)animated removedOnCompletion:(BOOL)remove {
    [self displayStatusBarWithStyle:UIStatusBarStyleBlackTranslucent animated:NO];
    
    [self.navController setToolbarHidden:NO];
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
    
    [self.navController setToolbarHidden:NO];
    
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
        
        UILabel *page = [[UILabel alloc] init];
        page.font = [UIFont systemFontOfSize:17];
        page.adjustsFontSizeToFitWidth = YES;
        page.textColor = [UIColor darkGrayColor];
        page.textAlignment = UITextAlignmentRight;
        page.tag = BLIOBOOKSEARCHCELLPAGETAG;
        [cell.contentView addSubview:page];
        [page release];
        
        UILabel *prefix = [[UILabel alloc] init];
        prefix.font = [UIFont systemFontOfSize:17];
        prefix.tag = BLIOBOOKSEARCHCELLPREFIXTAG;
        [cell.contentView addSubview:prefix];
        [prefix release];
        
        UILabel *match = [[UILabel alloc] init];
        match.font = [UIFont boldSystemFontOfSize:17];
        match.tag = BLIOBOOKSEARCHCELLMATCHTAG;
        [cell.contentView addSubview:match];
        [match release];
        
        UILabel *suffix = [[UILabel alloc] init];
        suffix.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        suffix.font = [UIFont systemFontOfSize:17];
        suffix.tag = BLIOBOOKSEARCHCELLSUFFIXTAG;
        [cell.contentView addSubview:suffix];
        [suffix release];
    }
    
    // Configure the cell...
    BlioBookSearchResults *result = [self.searchResults objectAtIndex:[indexPath row]];
    
    UILabel *page = (UILabel *)[cell.contentView viewWithTag:BLIOBOOKSEARCHCELLPAGETAG];
    
    if (self.bookView) {
        NSInteger pageNum = [self.bookView pageNumberForBookmarkPoint:result.bookmark];
        NSString *displayPage = [[self.bookView contentsDataSource] displayPageNumberForPageNumber:pageNum];
        page.text = [NSString stringWithFormat:@"p.%@", displayPage];
    } else {
        page.text = [NSString stringWithFormat:@"p.%d", result.bookmark.layoutPage];
    }
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
    suffix.frame = CGRectMake(CGRectGetMaxX(matchFrame), matchFrame.origin.y, CGRectGetWidth(cell.contentView.frame) - CGRectGetMaxX(matchFrame) - 10, prefixFrame.size.height);
    //suffix.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.3];
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


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
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
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
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self.bookSearchController cancel];
    [self.searchResults removeAllObjects];
    currentSearchResult = -1;
    [self.tableView reloadData];
    
    if (searchText) {
    //BlioBookmarkPoint *currentBookmarkPoint = self.bookView.currentBookmarkPoint;
        [self.bookSearchController findString:searchText fromBookmarkPoint:nil];
    }

}

#pragma mark -
#pragma mark BlioBookSearchDelegate

- (void)searchController:(BlioBookSearchController *)aSearchController didFindString:(NSString *)searchString atBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint withPrefix:(NSString *)prefix withSuffix:(NSString *)suffix {
    //NSLog(@"searchController didFindString '%@' at page %d paragraph %d word %d element %d", searchString, bookmarkPoint.layoutPage, bookmarkPoint.blockOffset, bookmarkPoint.wordOffset, bookmarkPoint.elementOffset);
    //NSString *prefixString = nil;
//    NSString *resultString = searchString;
//    
//    for (int i = [prefix count] - 1; i >= 0; i--) {
//        NSString *nextWord = [prefix objectAtIndex:i];
//        if (([resultString length] + [nextWord length]) <= RESULTSPREFIXSTRINGMAXLENGTH) {
//            if (prefixString) {
//                prefixString = [NSString stringWithFormat:@"%@ %@", nextWord, prefixString];
//            } else {
//                prefixString = [NSString stringWithString:nextWord];
//            }
//            resultString = [NSString stringWithFormat:@"%@ %@", prefixString, searchString];
//        } else {
//            break;
//        }
//    }
    
    //resultString = [NSString stringWithFormat:@"%@ %@", resultString, [suffix componentsJoinedByString:@" "]];
    
    //NSString *resultString = [NSString stringWithFormat:@"%@%@%@", prefix, searchString, suffix];
    //NSLog(@"resultString: %@", resultString);
    
    BlioBookSearchResults *result = [[BlioBookSearchResults alloc] init];
    result.prefix = prefix;
    result.match  = searchString;
    result.suffix = suffix;
    result.bookmark = bookmarkPoint;
    
//    [self.searchResults addObject:[NSString stringWithFormat:@"p.%d %@", bookmarkPoint.layoutPage, resultString]];
    [self.searchResults addObject:result];
    [result release];
    [self.tableView reloadData];
    [aSearchController findNextOccurrence];
}

- (void)searchControllerDidReachEndOfBook:(BlioBookSearchController *)aSearchController {
    NSLog(@"Search reached end of book");
    [aSearchController findNextOccurrence];
}

- (void)searchControllerDidCompleteSearch:(BlioBookSearchController *)aSearchController {
    NSLog(@"Search complete");
}
    
@end

@implementation BlioBookSearchResults

@synthesize prefix, match, suffix, bookmark;

- (void)dealloc {
    self.prefix = nil;
    self.match = nil;
    self.suffix = nil;
    self.bookmark = nil;
    [super dealloc];
}

@end

