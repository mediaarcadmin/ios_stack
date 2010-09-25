//
//  BlioBookSearchResultsTableViewController.m
//  BlioApp
//
//  Created by matt on 11/09/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioBookSearchResultsTableViewController.h"
#import "BlioBookSearchResult.h"
#import <libEucalyptus/THUIDeviceAdditions.h>

#define BLIOBOOKSEARCHCELLPAGETAG 1233
#define BLIOBOOKSEARCHCELLPREFIXTAG 1234
#define BLIOBOOKSEARCHCELLMATCHTAG 1235
#define BLIOBOOKSEARCHCELLSUFFIXTAG 1236
#define BLIOBOOKSEARCHSTATUSHEIGHT 66

@interface BlioBookSearchResultsTableView : UITableView
@end

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

@interface BlioBookSearchResultsTableViewController()

@property (nonatomic, retain) UIView *dimmingView;
@property (nonatomic, retain) BlioBookSearchStatusView *statusView;

@end

@implementation BlioBookSearchResultsTableViewController

@synthesize searchResults;
@synthesize resultsDelegate, resultsFormatter;
@synthesize dimmingView, statusView;

- (void)dealloc {
    self.searchResults = nil;
    self.resultsDelegate = nil;
    self.resultsFormatter = nil;
    self.dimmingView = nil;
    self.statusView = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark Initialization


- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:style])) {
        self.searchResults = [NSMutableArray array];
    }
    return self;
}

#pragma mark -
#pragma mark View lifecycle

- (void)loadView {
    BlioBookSearchResultsTableView *aTableView = [[BlioBookSearchResultsTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView = aTableView;
    [aTableView release];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        UIView *aDimmingView = [[UIView alloc] initWithFrame:self.tableView.bounds];
        [aDimmingView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [aDimmingView setBackgroundColor:[UIColor colorWithHue:0 saturation:0 brightness:0.2f alpha:1]];
        [aDimmingView setAlpha:0];
        [self.view addSubview:aDimmingView];
        self.dimmingView = aDimmingView;
        [aDimmingView release];
    } else {
        self.tableView.showsVerticalScrollIndicator = NO;
    }
    
    BlioBookSearchStatusView *aStatusView = [[BlioBookSearchStatusView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), BLIOBOOKSEARCHSTATUSHEIGHT)];
    [aStatusView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [aStatusView setStatus:kBlioBookSearchStatusIdle matches:0];
    [aStatusView setBackgroundColor:[UIColor colorWithHue:0 saturation:0 brightness:0.9f alpha:1]];
    [aStatusView setTarget:self];
    [aStatusView setAction:@selector(continueSearching)];
    [self.tableView setTableFooterView:aStatusView];
    self.statusView = aStatusView;
    [aStatusView release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Override to allow orientations other than the default portrait orientation.
    return YES;
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
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
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
    BlioBookSearchResult *result = [self.searchResults objectAtIndex:[indexPath row]];
    
    UILabel *page = (UILabel *)[cell.contentView viewWithTag:BLIOBOOKSEARCHCELLPAGETAG];
    NSString *pageNumberText;
    if (self.resultsFormatter) {
        pageNumberText = [self.resultsFormatter displayPageNumberForBookmarkPoint:result.bookmarkRange.startPoint];
        
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
    [self.resultsDelegate resultsController:self didSelectResultAtIndex:[indexPath row]];
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
#pragma mark Private Methods

- (void)setDimmed:(BOOL)dimmed {
    [self.dimmingView setAlpha:dimmed];
}

- (void)continueSearching {
    [self.resultsDelegate resultsControllerDidContinueSearch:self];
}

#pragma mark -
#pragma mark Public Methods
- (void)setSearchStatus:(BlioBookSearchStatus)newStatus {
    
    // Show/hide the dim view
    switch (newStatus) {
        case kBlioBookSearchStatusIdle:
            [self setDimmed:YES];
            break;
        default:
            [self setDimmed:NO];
            break;
    }

    [self.statusView setStatus:newStatus matches:[self.searchResults count]];
}

- (void)addResult:(BlioBookSearchResult *)result {
    [self.searchResults addObject:result];
    [self.tableView reloadData];
//    NSIndexPath *newRow = [NSIndexPath indexPathForRow:([self.searchResults count] - 1) inSection:0];
//    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newRow] withRowAnimation:UITableViewRowAnimationNone];
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

@implementation BlioBookSearchResultsTableView

- (void)setContentInset:(UIEdgeInsets)newInset {
    // Don't adjust the inset on the iPad - it will be in a popover
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [super setContentInset:UIEdgeInsetsZero];
    } else {
        [super setContentInset:newInset];
    }
}

@end