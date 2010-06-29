//
//  BlioStoreTabViewController.m
//  BlioApp
//
//  Created by matt on 05/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioStoreTabViewController.h"
#import "BlioStoreFeaturedController.h"
#import "BlioStoreCategoriesController.h"
#import "BlioStoreSearchController.h"
#import "BlioStoreArchiveViewController.h"
#import "BlioStoreWebsiteViewController.h"
#import "BlioStoreFreeBooksViewController.h"
#import "BlioStoreBookViewController.h"

#import "BlioSplitViewController.h"

@interface BlioStoreTabViewController()
@property (nonatomic, assign) id<BlioProcessingDelegate> processingDelegate;
@end

@implementation BlioStoreTabViewController

@synthesize processingDelegate, managedObjectContext;

- (void)dealloc {
    self.processingDelegate = nil;
    [super dealloc];
}

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/
- (id)init {
    return [self initWithProcessingDelegate:nil managedObjectContext:nil];
}

- (id)initWithProcessingDelegate:(id<BlioProcessingDelegate>)aProcessingDelegate managedObjectContext:(NSManagedObjectContext*)moc
{
    if ((self = [super init])) {
        self.processingDelegate = aProcessingDelegate;
		self.managedObjectContext = moc;
        self.delegate = self;
        
        UIBarButtonItem *aDoneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done",@"\"Done\" bar button") style:UIBarButtonItemStyleBordered target:self action:@selector(dismissTabView:)];        
        
//        BlioStoreFeaturedController* vc1 = [[BlioStoreFeaturedController alloc] init];
//        UINavigationController* nc1 = [[UINavigationController alloc] initWithRootViewController:vc1];
//        [vc1.navigationItem setRightBarButtonItem:aDoneButton];
//        [vc1 release];

		UIViewController * freeBooksViewController = nil; 

		BlioStoreFreeBooksViewController* vc1 = [[BlioStoreFreeBooksViewController alloc] init];
		[vc1 setManagedObjectContext:self.managedObjectContext];
        NSURL *featuredFeedURL = [NSURL URLWithString:@"http://www.feedbooks.com/userbooks/top.atom?range=week"];
        BlioStoreFeed *featuredFeed = [[BlioStoreFeed alloc] init];
        [featuredFeed setTitle:NSLocalizedString(@"Featured Books",@"\"Featured Books\" table section header")];
        [featuredFeed setFeedURL:featuredFeedURL];
        [featuredFeed setParserClass:[BlioStoreFeedBooksParser class]];
		featuredFeed.sourceID = BlioBookSourceFeedbooks;		
		[vc1 setFeeds:[NSArray arrayWithObject:featuredFeed]];
		[featuredFeed release];
		[vc1 setProcessingDelegate:self.processingDelegate];

		vc1.title = NSLocalizedString(@"Free Books",@"\"Free Books\" view controller header");
        
		UITabBarItem* theItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Free Books",@"\"Free Books\" tab bar title") image:[UIImage imageNamed:@"icon-freebooks.png"] tag:kBlioStoreFreeBooksTag];
        vc1.tabBarItem = theItem;
        [theItem release];
		
		UINavigationController* nc1 = [[UINavigationController alloc] initWithRootViewController:vc1];
        
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			BlioSplitViewController * aSplitViewController = [[[BlioSplitViewController alloc] init] autorelease];
			aSplitViewController.tabBarItem = theItem;
			BlioStoreBookViewController *aEntityController = [[[BlioStoreBookViewController alloc] initWithNibName:@"BlioStoreBookView"
																										   bundle:[NSBundle mainBundle]] autorelease];
			[aEntityController setProcessingDelegate:self.processingDelegate];
			[aEntityController setManagedObjectContext:self.managedObjectContext];
//			[aEntityController setTitle:[entity title]];
//			[aEntityController setEntity:entity];
//			[aEntityController setFeed:feed];
			[aEntityController.navigationItem setRightBarButtonItem:aDoneButton];
			
			vc1.detailViewController = aEntityController;
			
			[aSplitViewController setViewControllers:[NSArray arrayWithObjects:nc1,[[[UINavigationController alloc] initWithRootViewController:aEntityController] autorelease],nil]];
			freeBooksViewController = aSplitViewController;

		}
		else {
			[vc1.navigationItem setRightBarButtonItem:aDoneButton];
			freeBooksViewController = nc1;
			freeBooksViewController.tabBarItem = theItem;

		}
		
#else
		[vc1.navigationItem setRightBarButtonItem:aDoneButton];
        freeBooksViewController = nc1;
#endif		
		
		[vc1 release];
		
		
//        BlioStoreCategoriesController* vc2 = [[BlioStoreCategoriesController alloc] init];
//		[vc2 setManagedObjectContext:self.managedObjectContext];
//        NSURL *feedbooksFeedURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"feedbooks" ofType:@"atom" inDirectory:@"Feeds"]];
//        BlioStoreFeed *feedBooksFeed = [[BlioStoreFeed alloc] init];
//        [feedBooksFeed setTitle:@"Feedbooks"];
//        [feedBooksFeed setFeedURL:feedbooksFeedURL];
//        [feedBooksFeed setParserClass:[BlioStoreLocalParser class]];
//		feedBooksFeed.sourceID = BlioBookSourceFeedbooks;
//        NSURL *googleFeedURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"googlebooks" ofType:@"atom" inDirectory:@"Feeds"]];
//        BlioStoreFeed *googleBooksFeed = [[BlioStoreFeed alloc] init];
//        [googleBooksFeed setTitle:@"Google Books"];
//        [googleBooksFeed setFeedURL:googleFeedURL];
//        [googleBooksFeed setParserClass:[BlioStoreLocalParser class]];
//		googleBooksFeed.sourceID = BlioBookSourceGoogleBooks;
//        [vc2 setFeeds:[NSArray arrayWithObjects:feedBooksFeed, googleBooksFeed, nil]];
//        [feedBooksFeed release];
//        [googleBooksFeed release];
//        
//        [vc2 setProcessingDelegate:self.processingDelegate];
//        
//        UINavigationController* nc2 = [[UINavigationController alloc] initWithRootViewController:vc2];
//        [vc2.navigationItem setRightBarButtonItem:aDoneButton];
//        [vc2 release];
//        
//        BlioStoreSearchController* vc3 = [[BlioStoreSearchController alloc] init];
//		[vc3 setManagedObjectContext:self.managedObjectContext];
//        [vc3 setProcessingDelegate:self.processingDelegate];
//        
//        UINavigationController* nc3 = [[UINavigationController alloc] initWithRootViewController:vc3];
//        [vc3.navigationItem setRightBarButtonItem:aDoneButton];
//        [vc3 release];
        
        BlioStoreArchiveViewController* vc4 = [[BlioStoreArchiveViewController alloc] init];
		vc4.managedObjectContext = self.managedObjectContext;
		vc4.processingDelegate = self.processingDelegate;
        UINavigationController* nc4 = [[UINavigationController alloc] initWithRootViewController:vc4];
        [vc4.navigationItem setRightBarButtonItem:aDoneButton];
        [vc4 release];
        
        //BlioStoreDownloadsController* vc5 = [[BlioStoreDownloadsController alloc] init];
        //UINavigationController* nc5 = [[UINavigationController alloc] initWithRootViewController:vc5];
        //[vc5.navigationItem setRightBarButtonItem:aDoneButton];
        //[vc5 release];
        
        BlioStoreWebsiteViewController* vc5 = [[BlioStoreWebsiteViewController alloc] init];
        UINavigationController* nc5 = [[UINavigationController alloc] initWithRootViewController:vc5];
        [vc5.navigationItem setRightBarButtonItem:aDoneButton];
        [vc5 release];
        
		
        NSArray* controllers = [NSArray arrayWithObjects:nc5, freeBooksViewController, nc4, nil];
        self.viewControllers = controllers;
        
        [nc1 release];
//        [nc2 release];
//        [nc3 release];
        [nc4 release];
        [nc5 release];
        
        [aDoneButton release];
    }
    return self;
}

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
    return YES;
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)dismissTabView:(id)sender {
    [self.parentViewController dismissModalViewControllerAnimated:YES];
}

@end
