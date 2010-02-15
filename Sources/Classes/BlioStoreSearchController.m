//
//  BlioStoreGetBooksController.m
//  BlioApp
//
//  Created by matt on 05/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioStoreSearchController.h"

#define NARROWSEARCHBARWIDTH 260
#define WIDESEARCHBARWIDTH 320
#define DONEBUTTONWIDTH 50

@interface BlioStoreSearchTableView : UITableView {
    UISearchBar *searchBar;
    UIView *dimmingView;
}

@property (nonatomic, assign) UISearchBar *searchBar;
@property (nonatomic, retain) UIView *dimmingView;
- (void)setDimmed:(BOOL)dimmed;

@end

@interface BlioStoreSearchController()
@property (nonatomic, retain) BlioStoreSearchTableView *dimmableTableView;
@end

@implementation BlioStoreSearchController

@synthesize savedSearchTerm, searchBar;
@synthesize dimmingView, noResultsLabel, noResultsMessage, doneButton, fillerButton, dimmableTableView;

- (void)dealloc {
    self.savedSearchTerm = nil;
    self.searchBar = nil;
    self.dimmingView = nil;
    self.noResultsLabel = nil;
    self.noResultsMessage = nil;
    self.doneButton = nil;
    self.fillerButton = nil;
    self.dimmableTableView = nil;
    [super dealloc];
}

- (id)init {
    if ((self = [super initWithStyle:UITableViewStylePlain])) {
        self.title = @"Search";
        
        // UIBarStyleDefault for a UISearchBar doesn't match UIBarStyleDefault for a UINavigationBar
        // This tint is pretty close, but both should be set to make it seamless
        UIColor *matchedTintColor = [UIColor colorWithHue:0.595 saturation:0.267 brightness:0.68 alpha:1];
        self.navigationController.navigationBar.tintColor = matchedTintColor;
        
        UITabBarItem* theItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemSearch tag:kBlioStoreSearchTag];
        self.tabBarItem = theItem;
        [theItem release];
        
        UISearchBar *aSearchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
        [aSearchBar setShowsCancelButton:NO];
        [aSearchBar setPlaceholder:@"Search"];
        [aSearchBar setTintColor:matchedTintColor];
        [aSearchBar setDelegate:self];
        [aSearchBar sizeToFit];
        [self.navigationItem setTitleView:aSearchBar];
        self.searchBar = aSearchBar;
        [aSearchBar release];
                
        UIView *fillerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,DONEBUTTONWIDTH,self.searchBar.frame.size.height)];
        [fillerView setBackgroundColor:[UIColor clearColor]];
        UIBarButtonItem *filler = [[UIBarButtonItem alloc] initWithCustomView:fillerView];
        [fillerView release];
        self.fillerButton = filler;
        [filler release];
        
        BlioStoreFeed *feedBooksFeed = [[BlioStoreFeed alloc] init];
        [feedBooksFeed setTitle:@"Feedbooks"];
        [feedBooksFeed setParserClass:[BlioStoreFeedBooksParser class]];
        BlioStoreFeed *googleBooksFeed = [[BlioStoreFeed alloc] init];
        [googleBooksFeed setTitle:@"Google Books"];
        [googleBooksFeed setParserClass:[BlioStoreGoogleBooksParser class]];
        [self setFeeds:[NSArray arrayWithObjects:feedBooksFeed, googleBooksFeed, nil]];
        [feedBooksFeed release];
        [googleBooksFeed release];
    }
    return self;
}
/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

- (void)loadView {
    BlioStoreSearchTableView *aTableView = [[BlioStoreSearchTableView alloc] initWithFrame:CGRectMake(0,0,320,460)];
    [aTableView setSearchBar:self.searchBar];
    self.tableView = aTableView;
    self.dimmableTableView = aTableView;
    [aTableView release];
}

- (void)viewDidLoad
{
    if (nil != self.savedSearchTerm)
	{
        [self.searchBar setText:savedSearchTerm];        
        self.savedSearchTerm = nil;
        [self.dimmableTableView setDimmed:NO];
    } else {
        [self.dimmableTableView setDimmed:YES];
    }
	
	[self.tableView reloadData];
	
}

- (void)viewDidUnload
{
    self.savedSearchTerm = [self.searchBar text];
}

- (void)performSearch {
    if (![self.feeds count]) return;
        
    for (BlioStoreFeed *feed in self.feeds) {
        if (nil != feed.parserClass) {
            feed.parser = nil;
            @try {
                BlioStoreBooksSourceParser* aParser = [[feed.parserClass alloc] init];
                feed.parser = aParser;
                [aParser release];
            }
            @catch (NSException * e) {
                NSLog(@"Warning: BlioStore couldn't create Parser of class: %@", feed.parserClass);
            }
        }
        
        if (feed.parser && self.searchBar.text) {
            NSURL *queryUrl = [feed.parser queryUrlForString:self.searchBar.text];
            feed.parser.delegate = self;
            if (nil != queryUrl) [feed.parser startWithURL:queryUrl];
        }
    }    
}



#pragma mark -
#pragma mark UISearch Delegate Methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.doneButton = self.navigationItem.rightBarButtonItem;
    [self.navigationItem setRightBarButtonItem:self.fillerButton animated:YES];
    [self performSelector:@selector(hideDoneButton) withObject:nil afterDelay:0.35f];
    [self.dimmableTableView setDimmed:YES];
    
    for (BlioStoreFeed *feed in self.feeds) {
        [feed.categories removeAllObjects];
        [feed.entities removeAllObjects];
    }
    [self.tableView reloadData];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [self.navigationItem setRightBarButtonItem:self.doneButton animated:YES];
    [UIView beginAnimations:@"showDoneButton" context:nil];
    [UIView setAnimationDuration:0.35f];
    [self.searchBar sizeToFit];
    [UIView commitAnimations];
}

- (void)hideDoneButton {
    [UIView beginAnimations:@"hideDoneButton" context:nil];
    [UIView setAnimationDuration:0.35f];
    [self.navigationItem setRightBarButtonItem:nil animated:NO];
    [self.searchBar sizeToFit];
    [UIView commitAnimations];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)aSearchBar {
    [self performSearch];
    [self.dimmableTableView setDimmed:NO];
    [self.searchBar resignFirstResponder];
}

@end

@implementation BlioStoreSearchTableView

#pragma mark -
#pragma mark Touch handling

@synthesize searchBar, dimmingView;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        UIView *aDimmingView = [[UIView alloc] initWithFrame:self.bounds];
        aDimmingView.backgroundColor = [UIColor darkGrayColor];
        [self addSubview:aDimmingView];
        self.dimmingView = aDimmingView;
        [aDimmingView release];
    }
    return self;
}

- (void)dealloc {
    self.searchBar = nil;
    self.dimmingView = nil;
    [super dealloc];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.searchBar resignFirstResponder];
    [super touchesBegan:touches withEvent:event];
}

- (void)setDimmed:(BOOL)dimmed {
    if (dimmed) {
        [self.dimmingView setAlpha:1.0f];
        [self setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        [self bringSubviewToFront:self.dimmingView];
        [self setScrollEnabled:NO];
    } else {
        [self.dimmingView setAlpha:0.0f];
        [self setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        [self setScrollEnabled:YES];
    }
}

@end


