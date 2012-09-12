//
//  BlioVoiceOverTextController.m
//  BlioApp
//
//  Created by Don Shin on 10/6/11.
//  Copyright (c) 2011 CrossComm, Inc. All rights reserved.
//

#import "BlioVoiceOverTextController.h"
#import "BlioReadingVoiceSettingsViewController.h"
#import "BlioVOTipsSettingsController.h"

@implementation BlioVoiceOverTextController

#pragma mark -
#pragma mark Initialization

- (id)init
{
	self = [super init];
	if (self)
	{
		self.title = NSLocalizedString(@"VoiceOver Quick Start",@"\"VoiceOver Quick Start\" view controller title.");
#ifdef TOSHIBA
		NSString* quickstartText = [NSString stringWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/voiceover-quickstart-Toshiba.html"] encoding:NSUTF8StringEncoding error:NULL];
#else
		NSString* quickstartText = [NSString stringWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/voiceover-quickstart.html"] encoding:NSUTF8StringEncoding error:NULL];
#endif
		textView = [[UIWebView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
		[textView loadHTMLString:quickstartText baseURL:nil];
		[textView setScalesPageToFit:YES];
		self.view = textView;
		textView.delegate = self;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			self.contentSizeForViewInPopover = CGSizeMake(320, 550);
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

#pragma mark -
#pragma mark UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([[request.URL absoluteString] rangeOfString:@"blioapp://"].location != NSNotFound) {
        // command to Obj-C side
        NSArray *urlArray = [[request.URL absoluteString] componentsSeparatedByString:@"//"];
        if ([urlArray count] < 2) return NO;
        NSString * selectorString = [urlArray objectAtIndex:1];
        SEL providedSelector = NSSelectorFromString(selectorString);
        if ([self respondsToSelector:providedSelector]) [self performSelector:providedSelector];
        return NO;
    }
    return YES;
}

#pragma mark -
#pragma mark possible commands from web view

-(void)presentDownloadVoices {
    NSLog(@"%@",NSStringFromSelector(_cmd));
    BlioReadingVoiceSettingsViewController * vc = [[[BlioReadingVoiceSettingsViewController alloc] init] autorelease];
    [self.navigationController pushViewController:vc animated:YES];
}
-(void)presentDetailedHelp {
    NSLog(@"%@",NSStringFromSelector(_cmd));
    BlioVOTipsSettingsController * vc = [[[BlioVOTipsSettingsController alloc] init] autorelease];
    [self.navigationController pushViewController:vc animated:YES];
}

@end

