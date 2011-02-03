//
//  BlioHelpSettingsController.m
//  BlioApp
//
//  Created by Arnold Chien on 7/30/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import "BlioHelpSettingsController.h"


@implementation BlioHelpSettingsController

#pragma mark -
#pragma mark Initialization

- (id)init
{
	self = [super init];
	if (self)
	{
		self.title = NSLocalizedString(@"Help",@"\"Help\" view controller title.");
		NSString* helpFilepath;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) 
			helpFilepath = @"/userdoc-ipad.html";
		else
			helpFilepath = @"/userdoc.html";

		NSString* helpText = [NSString stringWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:helpFilepath] encoding:NSUTF8StringEncoding error:NULL];
		textView = [[UIWebView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
		[textView loadHTMLString:helpText baseURL:nil];
		[textView setScalesPageToFit:YES];
		self.view = textView;
		textView.delegate = self;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			self.contentSizeForViewInPopover = CGSizeMake(320, 400);
		}		
	}
	return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if ([[[[NSBundle mainBundle] infoDictionary] objectForKey:@"BlioLibraryViewDisableRotation"] boolValue])
        return NO;
    else if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown && UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) return NO;
	return YES;
}

#pragma mark -
#pragma mark UIWebViewDelegate

//- (void)webViewDidFinishLoad:(UIWebView *)webView {
//	NSString *output = [webView stringByEvaluatingJavaScriptFromString:@"document.body.offsetHeight;"];
//	NSInteger webviewHeight = [output intValue]+10;
//	if (webviewHeight > 600) webviewHeight = 600;
//	self.contentSizeForViewInPopover = CGSizeMake(320, webviewHeight);
//}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if (![request.URL isFileURL] && navigationType == UIWebViewNavigationTypeLinkClicked) {
		[[UIApplication sharedApplication] openURL:request.URL];
		return NO;
	}
	return YES;
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


- (void)dealloc {
	[textView release];
    [super dealloc];
}


@end

