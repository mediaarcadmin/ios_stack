//
//  BlioPrivacyTextControllerViewController.m
//  BlioApp
//
//  Created by Arnold Chien on 8/7/12.
//  Copyright (c) 2012 Kurzweil Technologies Inc. All rights reserved.
//

#import "BlioWebTextController.h"

@implementation BlioWebTextController

@synthesize contentView;
@synthesize activityIndicator;

- (id)initWithURL:(NSString*)url
{
    self = [super init];
    self.contentView = [[UIWebView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    NSURL *privacyURL = [NSURL URLWithString:url];
    self.contentView.delegate = (id)self;
    [self.contentView loadRequest:[NSURLRequest requestWithURL:privacyURL]];
    [self.contentView setScalesPageToFit:YES]; 
    [self initActivityIndicator];
    return self;
}

- (void)initActivityIndicator {
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.center = CGPointMake((self.view.bounds.size.width)/2, (self.view.bounds.size.height)/2);
    [self.view addSubview:self.activityIndicator];
    [self.activityIndicator startAnimating];
}

- (void)dealloc 
{
    self.contentView.delegate = nil;
    self.contentView = nil;
    self.activityIndicator = nil;
    [super dealloc];
}

- (void)loadView
{
	self.view = self.contentView;
	[self.contentView release];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [self.activityIndicator stopAnimating];
    
}

#pragma mark - UIWebView delegate methods

/*
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    //[self.activityIndicator stopAnimating];
    // TODO Define expected behavior
}
 */

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.activityIndicator stopAnimating];

    
}


@end
