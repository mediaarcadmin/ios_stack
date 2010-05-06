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
        self.title = NSLocalizedString(@"Search",@"\"Search\" title in view controller");
        
        // UIBarStyleDefault for a UISearchBar doesn't match UIBarStyleDefault for a UINavigationBar
        // This tint is pretty close, but both should be set to make it seamless
        UIColor *matchedTintColor = [UIColor colorWithHue:0.595 saturation:0.267 brightness:0.68 alpha:1];
        self.navigationController.navigationBar.tintColor = matchedTintColor;
        
        UITabBarItem* theItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemSearch tag:kBlioStoreSearchTag];
        self.tabBarItem = theItem;
        [theItem release];
        
        UISearchBar *aSearchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
        [aSearchBar setShowsCancelButton:NO];
        [aSearchBar setPlaceholder:NSLocalizedString(@"Search",@"\"Search\" placeholder text in Search bar")];
        [aSearchBar setTintColor:matchedTintColor];
        [aSearchBar setDelegate:self];
        [aSearchBar sizeToFit];
        [aSearchBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
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

- (void)layoutSearchBar {
    CGRect searchBounds = self.searchBar.bounds;
    searchBounds.size.height = self.navigationController.navigationBar.frame.size.height;
    [self.searchBar setBounds:searchBounds];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self layoutSearchBar];
}

- (void)loadView {
    BlioStoreSearchTableView *aTableView = [[BlioStoreSearchTableView alloc] initWithFrame:CGRectMake(0,0,320,460)];
    [aTableView setSearchBar:self.searchBar];
    self.tableView = aTableView;
    self.dimmableTableView = aTableView;
    [aTableView release];
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[self.view addSubview:activityIndicatorView];
	activityIndicatorView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
	activityIndicatorView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin|
											  UIViewAutoresizingFlexibleRightMargin|
											  UIViewAutoresizingFlexibleTopMargin|
											  UIViewAutoresizingFlexibleBottomMargin);
	[activityIndicatorView stopAnimating];
	activityIndicatorView.hidden = YES;
	[activityIndicatorView release];
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

	[activityIndicatorView startAnimating];
	activityIndicatorView.hidden = NO;
        
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

- (NSString *)getMoreCellLabelForSection:(NSUInteger) section {
	return [NSString stringWithFormat:NSLocalizedString(@"%@ Results",@"\"%@ Results\" See More Cell label"),[[self.feeds objectAtIndex:section] title]];
}

#pragma mark -
#pragma mark UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	NSUInteger row = [indexPath row];
	if (row%2 == 1) cell.backgroundColor = [UIColor colorWithRed:(226.0/255) green:(225.0/255) blue:(231.0/255) alpha:1];
	else cell.backgroundColor = [UIColor whiteColor];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	return 62;
}


#pragma mark -
#pragma mark UITableViewDataSource Methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell * cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
	
	// customize its appearance some before returning it to the tableView
	
	// cell background
	if (cell.backgroundView == nil) { // if no existing divider image, add one
		NSLog(@"background!");
		cell.backgroundView = [[[UIView alloc] initWithFrame:cell.bounds] autorelease];
		cell.backgroundView.autoresizesSubviews = YES;
		UIImageView * backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SearchCellDivider.png"]];
		[cell.backgroundView addSubview:backgroundImageView];
		backgroundImageView.frame = CGRectMake(0,0,cell.bounds.size.width,2);
		backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[backgroundImageView release];

		// label styling
		CGRect f = cell.textLabel.frame; 
		NSLog(@"rect: %f,%f,%f,%f", f.origin.x, f.origin.y, f.size.width, f.size.height);
		cell.textLabel.contentMode = UIViewContentModeRedraw;
		cell.textLabel.frame = CGRectMake(f.origin.x, f.origin.y + 30, f.size.width, f.size.height);
	}
	cell.textLabel.font = [UIFont boldSystemFontOfSize:16.0];
	cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:12.0];
	cell.detailTextLabel.text = [cell.detailTextLabel.text uppercaseString];
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	
	
	return cell;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    BlioStoreFeed *feed = [self.feeds objectAtIndex:section];
	NSInteger getMoreResultsCell = 0;
	if ([feed.entities count] < feed.totalResults) getMoreResultsCell = 1; // our data is less than the totalResults, so we need a "Get More Results" option.
    return [feed.categories count] + [feed.entities count] + getMoreResultsCell;
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
    [self layoutSearchBar];
    [UIView commitAnimations];
}

- (void)hideDoneButton {
    [UIView beginAnimations:@"hideDoneButton" context:nil];
    [UIView setAnimationDuration:0.35f];
    [self.navigationItem setRightBarButtonItem:nil animated:NO];
    [self.searchBar sizeToFit];
    [self layoutSearchBar];
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
        aDimmingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
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
        //  [self setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        [self setScrollEnabled:YES];
    }
}

@end


