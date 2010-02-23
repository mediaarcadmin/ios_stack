//
//  BlioWebToolsViewController.m
//  BlioApp
//
//  Created by matt on 23/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioWebToolsViewController.h"


@implementation BlioWebToolsViewController

- (id)initWithURL:(NSURL *)url {
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    UIWebView *aWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0,0,320,480)];
    [aWebView loadRequest:request];
    [aWebView setScalesPageToFit:YES];
    [request release];
    
    UIViewController *aVC = [[UIViewController alloc] init];
    aVC.view = aWebView;
    [aWebView release];
    
	if ((self = [super initWithRootViewController:aVC])) {
        // Configure controller
    }
    
    [aVC release];

    return self;
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

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

                 
- (void)viewWillAppear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    statusBarHiddenOnEntry = [[UIApplication sharedApplication] isStatusBarHidden];
    
    if (statusBarHiddenOnEntry)
        [[UIApplication sharedApplication] setStatusBarHidden:NO animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
    
    if (statusBarHiddenOnEntry)
        [[UIApplication sharedApplication] setStatusBarHidden:YES animated:YES];
}
    
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


- (void)dealloc {
    [super dealloc];
}


@end
