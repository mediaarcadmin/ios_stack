//
//  BlioVoiceOverTextController.m
//  BlioApp
//
//  Created by Don Shin on 10/6/11.
//  Copyright (c) 2011 CrossComm, Inc. All rights reserved.
//

#import "BlioVoiceOverTextController.h"

@implementation BlioVoiceOverTextController

#pragma mark -
#pragma mark Initialization

- (id)init
{
	self = [super init];
	if (self)
	{
		self.title = NSLocalizedString(@"VoiceOver Quick Start",@"\"VoiceOver Quick Start\" view controller title.");
		NSString* quickstartText = [NSString stringWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/voiceover-quickstart.html"] encoding:NSUTF8StringEncoding error:NULL];
		textView = [[UIWebView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
		[textView loadHTMLString:quickstartText baseURL:nil];
		[textView setScalesPageToFit:YES];
		self.view = textView;
		//textView.delegate = self;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			self.contentSizeForViewInPopover = CGSizeMake(320, 550);
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

