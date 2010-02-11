//
//  BlioStoreTabViewController.m
//  BlioApp
//
//  Created by matt on 05/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioStoreTabViewController.h"
#import "BlioStoreFeaturedController.h"
#import "BlioStoreCollectionController.h"
#import "BlioStoreGetBooksController.h"
#import "BlioStoreMyVaultController.h"
#import "BlioStoreDownloadsController.h"

@implementation BlioStoreTabViewController

- (void)dealloc {
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
    if ((self = [super init])) {
        self.delegate = self;
        
        UIBarButtonItem *aDoneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self action:@selector(dismissTabView:)];        
        
        BlioStoreFeaturedController* vc1 = [[BlioStoreFeaturedController alloc] init];
        UINavigationController* nc1 = [[UINavigationController alloc] initWithRootViewController:vc1];
        [vc1.navigationItem setRightBarButtonItem:aDoneButton];
        [vc1 release];
        
        BlioStoreCollectionController* vc2 = [[BlioStoreCollectionController alloc] init];
        NSURL *targetFeedURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"feedbooks" ofType:@"atom" inDirectory:@"Feeds"]];
        [vc2 setFeedURL:targetFeedURL];
        UINavigationController* nc2 = [[UINavigationController alloc] initWithRootViewController:vc2];
        [vc2.navigationItem setRightBarButtonItem:aDoneButton];
        [vc2 release];
        
        BlioStoreGetBooksController* vc3 = [[BlioStoreGetBooksController alloc] init];
        UINavigationController* nc3 = [[UINavigationController alloc] initWithRootViewController:vc3];
        [vc3.navigationItem setRightBarButtonItem:aDoneButton];
        [vc3 release];
        
        BlioStoreMyVaultController* vc4 = [[BlioStoreMyVaultController alloc] init];
        UINavigationController* nc4 = [[UINavigationController alloc] initWithRootViewController:vc4];
        [vc4.navigationItem setRightBarButtonItem:aDoneButton];
        [vc4 release];
        
        BlioStoreDownloadsController* vc5 = [[BlioStoreDownloadsController alloc] init];
        UINavigationController* nc5 = [[UINavigationController alloc] initWithRootViewController:vc5];
        [vc5.navigationItem setRightBarButtonItem:aDoneButton];
        [vc5 release];
        
        NSArray* controllers = [NSArray arrayWithObjects:nc1, nc2, nc3, nc4, nc5, nil];
        self.viewControllers = controllers;
        
        [nc1 release];
        [nc2 release];
        [nc3 release];
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

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

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
