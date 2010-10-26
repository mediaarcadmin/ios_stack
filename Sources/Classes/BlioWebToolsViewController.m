//
//  BlioWebToolsViewController.m
//  BlioApp
//
//  Created by matt on 23/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioWebToolsViewController.h"
#import "BlioAlertManager.h"

@implementation BlioWebToolsViewController

- (id)initWithURL:(NSURL *)url {
	
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    UIWebView *aWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0,0,320,480)];
    [aWebView loadRequest:request];
    [aWebView setScalesPageToFit:YES];
    [request release];
    
    UIViewController *aVC = [[UIViewController alloc] init];
    aVC.view = aWebView;
	
	activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)];
	
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	activityIndicatorView.center = CGPointMake(screenBounds.size.width/2, screenBounds.size.height/2);
	[activityIndicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
	activityIndicatorView.tag = ACTIVITY_INDICATOR;
	[[[UIApplication sharedApplication] keyWindow] addSubview:activityIndicatorView];
	
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
    
    if (statusBarHiddenOnEntry) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
		if ([[UIApplication sharedApplication] respondsToSelector:@selector(setStatusBarHidden:withAnimation:)]) [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
		else [(id)[UIApplication sharedApplication] setStatusBarHidden:NO animated:YES]; // typecast as id to mask deprecation warnings.							
#else
		[[UIApplication sharedApplication] setStatusBarHidden:NO animated:YES]; // original code 
#endif
	}
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
}

- (void)viewWillDisappear:(BOOL)animated {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
	} else {
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
	}
    
    if (statusBarHiddenOnEntry) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
		if ([[UIApplication sharedApplication] respondsToSelector:@selector(setStatusBarHidden:withAnimation:)]) [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
		else [(id)[UIApplication sharedApplication] setStatusBarHidden:YES animated:YES]; // typecast as id to mask deprecation warnings.							
#else
		[[UIApplication sharedApplication] setStatusBarHidden:YES animated:YES]; // original code 
#endif
	}
}
    

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
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


- (void)dealloc {
	[activityIndicatorView removeFromSuperview];	
	[activityIndicatorView release];
    [super dealloc];
}



-(void)webViewDidStartLoad:(UIWebView*)webView {
	[activityIndicatorView startAnimating];
}

-(void)webViewDidFinishLoad:(UIWebView*)webView {
	[activityIndicatorView stopAnimating];
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
	[activityIndicatorView stopAnimating];
	NSString* errorMsg = [error localizedDescription];
	NSLog(@"Error loading web page: %@",errorMsg);
	[BlioAlertManager showAlertWithTitle:@""
								 message:errorMsg 
								delegate:self 
					   cancelButtonTitle:@"OK"
					   otherButtonTitles:nil];
}

@end
