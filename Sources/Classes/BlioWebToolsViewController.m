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
	
	UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)];
	[activityIndicator setCenter:CGPointMake(160.0f, 208.0f)];
    [activityIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
	activityIndicator.tag = ACTIVITY_INDICATOR;
    [aWebView addSubview:activityIndicator];
	[activityIndicator release];
	
	aWebView.delegate = self;
	
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



-(void)webViewDidStartLoad:(UIWebView*)webView {
	UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[self.view viewWithTag:ACTIVITY_INDICATOR];
	[activityIndicator startAnimating];
}

-(void)webViewDidFinishLoad:(UIWebView*)webView {
	UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[self.view viewWithTag:ACTIVITY_INDICATOR];
	[activityIndicator stopAnimating];
	// Update navigation buttons
	if ( [(UIWebView*)self.topViewController.view canGoBack] ) 
		[(UISegmentedControl*)[(UIBarButtonItem*)self.topViewController.navigationItem.leftBarButtonItem  customView] 
			setImage:[UIImage imageNamed:@"back-black.png"] forSegmentAtIndex:0];		
	else 
		[(UISegmentedControl*)[(UIBarButtonItem*)self.topViewController.navigationItem.leftBarButtonItem  customView] 
			setImage:[UIImage imageNamed:@"back-gray.png"] forSegmentAtIndex:0];		
	if ( [(UIWebView*)self.topViewController.view canGoForward] ) 
		[(UISegmentedControl*)[(UIBarButtonItem*)self.topViewController.navigationItem.leftBarButtonItem  customView] 
			setImage:[UIImage imageNamed:@"forward-black.png"] forSegmentAtIndex:1];	
	else 
		[(UISegmentedControl*)[(UIBarButtonItem*)self.topViewController.navigationItem.leftBarButtonItem  customView] 
			setImage:[UIImage imageNamed:@"forward-gray.png"] forSegmentAtIndex:1];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// reintstate if we want to quit the webview when there's a loading error.
	//[self.visibleViewController dismissModalViewControllerAnimated:YES];
	[alertView release];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[self.view viewWithTag:ACTIVITY_INDICATOR];
	[activityIndicator stopAnimating];
	NSString* errorMsg = [error localizedDescription];
	NSLog(@"Error loading web page: %@",errorMsg);
	UIAlertView *errorAlert = [[UIAlertView alloc] 
							  initWithTitle:@"" message:errorMsg 
							  delegate:self cancelButtonTitle:nil
							  otherButtonTitles:@"OK", nil];
	[errorAlert show];
}

@end
