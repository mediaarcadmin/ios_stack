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
		self.title = NSLocalizedString(@"Blio Help",@"\"User Documentation\" view controller title.");
		NSString* helpText = [NSString stringWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/userdoc.html"] encoding:NSUTF8StringEncoding error:NULL];
		textView = [[UIWebView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
		[textView loadHTMLString:helpText baseURL:nil];
		[textView setScalesPageToFit:YES];
		self.view = textView;
		//textView.delegate = self;
	}
	return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if ([[[[NSBundle mainBundle] infoDictionary] objectForKey:@"BlioLibraryViewDisableRotation"] boolValue])
        return NO;
    else
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

