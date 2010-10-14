    //
//  BlioBookSearchPopoverController.m
//  BlioApp
//
//  Created by matt on 10/09/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "BlioBookSearchPopoverController.h"
#import "BlioBookSearchToolbar.h"
#import "BlioBookSearchResultsTableViewController.h"
#import "BlioBookSearchResult.h"
#import <libEucalyptus/EucBookContentsTableViewController.h>
#import "UIDevice+BlioAdditions.h"

#define SEARCHCOLLAPSEDPOPOVERHEIGHT 37
#define SEARCHEXPANDEDPOPOVERHEIGHT 660

@interface BlioBookSearchPopoverController() <BlioBookSearchToolbarDelegate, BlioBookSearchResultsDelegate, BlioBookSearchResultsFormatter>

@property (nonatomic, retain) BlioBookSearchResultsTableViewController *resultsController;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, retain) BlioBookSearchToolbar *toolbar;
@property (nonatomic, assign) UIBarButtonItem *barButtonItem;

- (void)setSearchStatus:(BlioBookSearchStatus)newStatus;
- (BOOL)shouldExpand;
- (void)highlightCurrentSearchResult;
- (void)removeHighlights;

@end

@implementation BlioBookSearchPopoverController

@synthesize resultsController, navigationController, toolbar;
@synthesize bookSearchController, bookView;
@synthesize barButtonItem;

- (void)dealloc {
    self.resultsController = nil;
    self.navigationController = nil;
    self.toolbar = nil;
    self.bookSearchController = nil;
    self.bookView = nil;
    self.barButtonItem = nil;
    [super dealloc];
}

- (id)init {
    BlioBookSearchResultsTableViewController *aResultsController = [[BlioBookSearchResultsTableViewController alloc] initWithStyle:UITableViewStylePlain];    
    UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:aResultsController];
    
    if ((self = [super initWithContentViewController:aNavigationController])) {
        self.resultsController = aResultsController;
        self.resultsController.resultsDelegate = self;
        self.navigationController = aNavigationController;
                
        BlioBookSearchToolbar *aSearchBar = [[BlioBookSearchToolbar alloc] init];
        [aSearchBar setDelegate:self];
        [aSearchBar setFrame:self.navigationController.navigationBar.bounds];
        [self.navigationController.navigationBar addSubview:aSearchBar];
        self.toolbar = aSearchBar;
        [aSearchBar release];
                        
        self.popoverContentSize = CGSizeMake(320, SEARCHCOLLAPSEDPOPOVERHEIGHT);
        currentSearchResult = -1;
        resultsInterval = [[UIDevice currentDevice] blioDeviceSearchInterval];
        
        self.delegate = self;
    }
    
    [aResultsController release];
    [aNavigationController release];
    return self;
}

- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)item permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated {
    self.barButtonItem = item;
    [super presentPopoverFromBarButtonItem:item permittedArrowDirections:arrowDirections animated:animated];
}

#pragma mark -
#pragma mark Highlight Results

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

- (void)removeHighlights {
    if ([self.bookView respondsToSelector:@selector(highlightWordAtBookmarkPoint:)]) {
        [self.bookView highlightWordAtBookmarkPoint:nil];
    }
}

#pragma mark -
#pragma mark Search Status

- (void)setSearchStatus:(BlioBookSearchStatus)newStatus {
    BlioBookSearchStatus currentStatus = searchStatus;
    searchStatus = newStatus;
    [self.resultsController setSearchStatus:newStatus];
    
    if ([self shouldExpand]) {
        self.popoverContentSize = CGSizeMake(320, SEARCHEXPANDEDPOPOVERHEIGHT);
    } else {
        self.popoverContentSize = CGSizeMake(320, SEARCHCOLLAPSEDPOPOVERHEIGHT);
    }
    
    switch (newStatus) {
        case kBlioBookSearchStatusIdle:
            break;
        default:
            if (currentStatus == kBlioBookSearchStatusIdle) {
                [self.resultsController.view setNeedsLayout];
            }
            break;
    }
}

- (BOOL)shouldExpand {
    BOOL expand = NO;
    
    if (searchStatus != kBlioBookSearchStatusIdle) {
        expand = YES;
    }
    
    if ([self.toolbar inlineMode]) {
        expand = NO;
    }
    
    return expand;
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

#pragma mark -
#pragma mark UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [self.bookSearchController cancel];
    if ([self isSearchActive]) {
        [self setSearchStatus:kBlioBookSearchStatusStopped];
    }
    
    [self removeHighlights];
}

#pragma mark -
#pragma mark Results Controller delegate

- (void)resultsController:(BlioBookSearchResultsTableViewController *)resultsController didSelectResultAtIndex:(NSUInteger)index {
    [self.toolbar.searchBar endEditing:YES];
    currentSearchResult = index;
    [self highlightCurrentSearchResult];
    self.popoverContentSize = CGSizeMake(320, SEARCHCOLLAPSEDPOPOVERHEIGHT);
    [self.toolbar setInlineMode:YES];
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
#pragma mark BlioBookSearchToolbar Delegate

- (void)nextResult {
    currentSearchResult++;
    [self highlightCurrentSearchResult];
}

- (void)previousResult {
    currentSearchResult--;
    [self highlightCurrentSearchResult];
}

#pragma mark -
#pragma mark SearchBar Delegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    if ([self.toolbar inlineMode]) {
        [self.toolbar setInlineMode:NO];
        
        if ([self shouldExpand]) {
            self.popoverContentSize = CGSizeMake(320, SEARCHEXPANDEDPOPOVERHEIGHT);
        }
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {    
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

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    if (self.barButtonItem) {
        // Force the popover back to the toolbar
        // Changing the popover size forces an animation that syncs with the keyboard
        // presenting the popover again ensures that the positioning at the end of the animation is correct
        CGSize currentSize = self.popoverContentSize;
        self.popoverContentSize = CGSizeMake(currentSize.width, currentSize.height + 1);
        self.popoverContentSize = currentSize;
        [self presentPopoverFromBarButtonItem:self.barButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
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

@end
