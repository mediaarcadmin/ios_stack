//
//  BlioVersionController.m
//  BlioApp
//
//  Created by Arnold Chien on 8/2/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import "BlioVersionController.h"


@implementation BlioVersionController


#pragma mark -
#pragma mark Initialization



- (id)init
{
	self = [super init];
	if (self)
	{
		self.title = NSLocalizedString(@"About",@"\"About\" view controller title.");
		// Get the marketing version from Info.plist.
		NSString* version = (NSString*)[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]; // @"CFBundleVersion" for build number
		//NSString* versionText = [NSString stringWithFormat:@"<center><p style=font-family:arial;font-size:50px;>Blio</center></p><center><p style=font-family:arial;font-size:35px;><i>Beta version %@</i></p></center><p>",version];  
		NSString* versionText = [NSString stringWithFormat:@"<html><body style=\"margin:20px 30px;\"><center><p style=font-family:arial;font-size:40px;><strong>Blio</strong> | <i>Version %@</i></p><hr></center>",version];
		NSString* creditsText = [NSString stringWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/credits.html"] encoding:NSUTF8StringEncoding error:NULL];
		NSString *resourcePath = [[[[NSBundle mainBundle] resourcePath]
								   stringByReplacingOccurrencesOfString:@"/" withString:@"//"]
								  stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
		textView = [[UIWebView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
		[textView loadHTMLString:[versionText stringByAppendingString:creditsText] baseURL:[NSURL URLWithString:
																							[NSString stringWithFormat:@"file:/%@//", resourcePath]]];
		[textView setScalesPageToFit:YES];
		self.view = textView;
		textView.delegate = self;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			self.contentSizeForViewInPopover = CGSizeMake(320, 500);
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


- (void)dealloc {
	[textView release];
    [super dealloc];
}


@end

