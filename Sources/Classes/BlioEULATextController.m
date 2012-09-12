//
//  BlioEULATextController.m
//  BlioApp
//
//  Created by Arnold Chien on 7/30/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import "BlioEULATextController.h"


@implementation BlioEULATextController


#pragma mark -
#pragma mark Initialization

- (id)init
{
	self = [super init];
	if (self)
	{
		self.title = NSLocalizedString(@"Terms of Use",@"\"Terms of Use\" view controller title.");
		NSString* eulaText = [NSString stringWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/eula.html"] encoding:NSUTF8StringEncoding error:NULL];
		textView = [[UIWebView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
		[textView loadHTMLString:eulaText baseURL:nil];
		[textView setScalesPageToFit:YES];
		self.view = textView;
		//textView.delegate = self;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			self.contentSizeForViewInPopover = CGSizeMake(600, 700);
		}				
	}
	return self;
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

