//
//  BlioWebAuthenticationViewController.m
//  StackApp
//
//  Created by Arnold Chien on 1/28/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import "BlioWebAuthenticationViewController.h"
#import "WACloudAccessToken.h"
#import "NSString+URLEncode.h"
#import "MediaArcPlatform.h"
#import "BlioAccountService.h"
#import "BlioStoreManager.h"
#import "BlioAlertManager.h"
#import "BlioStoreHelper.h"

NSString* ScriptNotify = @"<script type=\"text/javascript\">window.external = { 'Notify': function(s) { document.location = 'acs://settoken?token=' + s; }, 'notify': function(s) { document.location = 'acs://settoken?token=' + s; } };</script>";

@interface WACloudAccessToken (Private)
- (id)initWithDictionary:(NSDictionary *)dictionary;
@end

@interface BlioWebAuthenticationViewController ()

@end

@implementation BlioWebAuthenticationViewController 

- (id)initWithURL:(NSString *)url {
    if (self = [super init]) {
        intentionalPageAbort = NO;
        loginURL = [NSURL URLWithString:url];
        activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 64.0f, 64.0f)];
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        activityIndicatorView.center = CGPointMake(screenBounds.size.width/2, screenBounds.size.height/2);
        [activityIndicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
        [[[UIApplication sharedApplication] keyWindow] addSubview:activityIndicatorView];
    
    }
    return self;
}

- (void)loadView
{
    self.title = @"Log in";
    
    /*
     UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
     contentView.backgroundColor = [UIColor whiteColor];
     // important for view orientation rotation
     contentView.autoresizesSubviews = YES;
     contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
     self.view = contentView;
     [contentView release];
    */ 
    
    loginView = [[UIWebView alloc] init];
    loginView.autoresizesSubviews = YES;
    loginView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    loginView.delegate = self;
    loginView.scalesPageToFit = YES;
    
    self.view = loginView;
    [loginView release];
    
    // navigate to the login url
    NSURLRequest *request = [NSURLRequest requestWithURL:loginURL];
    [loginView loadRequest:request];

}

-(void)viewWillDisappear:(BOOL)animated {
    [activityIndicatorView stopAnimating];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    // See http://stackoverflow.com/questions/7883899/ios-5-uiwebview-delegate-webkit-discarded-an-uncaught-exception-in-the-webview
    ((UIWebView*)self.view).delegate = nil;
    [activityIndicatorView release];
    [_data release];
    [_url release];
    [super dealloc];
}

#pragma mark -
#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if(_data) {
        [_data release];
        _data = nil;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if(!_data)
        _data = [data mutableCopy];
    else
        [_data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (_data) {
        NSString *content = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
        NSRange headRange = [content rangeOfString:@"<head>"];
        NSRange throughHeadRange;
        throughHeadRange.location = 0;
        throughHeadRange.length = headRange.location + headRange.length;
        NSString* editedContent = [[[content substringWithRange:throughHeadRange] stringByAppendingString:ScriptNotify] stringByAppendingString:[content substringFromIndex:throughHeadRange.length]];
        [loginView loadHTMLString:editedContent baseURL:_url];
		[content release];
        [_data release];
        _data = nil;
    }
}

#pragma mark -
#pragma mark UIWebViewDelegate

// Quick and dirty alternative to JSON parsing.  From Steve Saxon (see below).
- (NSDictionary*)parsePairs:(NSString*)urlStr
{
	NSRange r = [urlStr rangeOfString:@"="];
	if(r.length == 0)
	{
		return nil;
	}
	
	NSString *token = [[urlStr substringFromIndex:r.location + 1] URLDecode];
	NSCharacterSet *objectMarkers = [NSCharacterSet characterSetWithCharactersInString:@"{}"];
	token = [token stringByTrimmingCharactersInSet:objectMarkers];
	
	NSError *regexError;
	NSMutableDictionary *pairs = [NSMutableDictionary dictionaryWithCapacity:10];
	
	// parse name-value pairs with string values
	//
	NSRegularExpression *nameValuePair;
	nameValuePair = [NSRegularExpression regularExpressionWithPattern:@"\"([^\"]*)\":\"([^\"]*)\""
															  options:0
																error:&regexError];
	NSArray *matches = [nameValuePair matchesInString:token
											  options:0
												range:NSMakeRange(0, token.length)];
    
	for (NSTextCheckingResult *result in matches) {
		for (int n = 1; n < [result numberOfRanges]; n += 2) {
			NSRange r = [result rangeAtIndex:n];
			if (r.length > 0) {
				NSString *name = [token substringWithRange:r];
				
				r = [result rangeAtIndex:n + 1];
				if (r.length > 0) {
					NSString* value = [token substringWithRange:r];
					
					[pairs setObject:value forKey:name];
				}
			}
		}
	}
	
	// parse name-value pairs with numeric values
	//
	nameValuePair = [NSRegularExpression regularExpressionWithPattern:@"\"([^\"]*)\":([0-9]*)"
															  options:0
																error:&regexError];
	matches = [nameValuePair matchesInString:token options:0 range:NSMakeRange(0, token.length)];
	
	for (NSTextCheckingResult *result in matches) {
		for (int n = 1; n < [result numberOfRanges]; n += 2){
			NSRange r = [result rangeAtIndex:n];
			if (r.length > 0) {
				NSString* name = [token substringWithRange:r];
				
				r = [result rangeAtIndex:n + 1];
				if (r.length > 0) {
					NSString* value = [token substringWithRange:r];
					NSNumber* number = [NSNumber numberWithInt:[value intValue]];
					
					[pairs setObject:number forKey:name];
				}
			}
		}
	}
	
	return pairs;
}

// The following is a modified version of a hack to register the javascript handler that ACS will call with the token.
// See http://www.stevesaxon.me/posts/2011//window-external-notify-in-ios-uiwebview

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    intentionalPageAbort = NO;
    NSString* urlString = [request.URL absoluteString];
    NSRange hostnameRange;
    NSRange firstDotRange = [urlString rangeOfString:@"."];
    if (firstDotRange.location == NSNotFound )
        return YES;
    hostnameRange.length = [[MediaArcPlatform sharedInstance].acsHost length];
    hostnameRange.location = firstDotRange.location + 1;
    if (![urlString hasPrefix:@"acs:"] &&
        ([[urlString substringWithRange:hostnameRange] compare:[MediaArcPlatform sharedInstance].acsHost] != NSOrderedSame) )
        return YES;
    if(_url)
    {
        // make the call re-entrant when we re-load the content ourselves
        if([_url isEqual:[request URL]])
        {
            return YES;
        }
        [_url release];
    }
    _url = [[request URL] retain];
    NSString* scheme = [_url scheme];
    if([scheme isEqualToString:@"acs"])
    {
        //NSLog(@"Javascript received string: %@", [_url absoluteString]);
        
        NSDictionary* pairs = [self parsePairs:[_url absoluteString]];
        BlioStoreHelper* helper = [[BlioStoreManager sharedInstance] storeHelperForSourceID:BlioBookSourceOnlineStore];
        if (pairs)
        {
            WACloudAccessToken* accessToken = [[WACloudAccessToken alloc] initWithDictionary:pairs];
            helper.token =  accessToken.securityToken;
            helper.timeout = accessToken.expireDate;
            [[BlioStoreManager sharedInstance] saveToken];
            [accessToken release];
            [[BlioLoginService sharedInstance] checkin];
            [self.navigationController popToRootViewControllerAnimated:NO];
        }
        [[BlioStoreManager sharedInstance] loginFinishedForSourceID:helper.sourceID];
        intentionalPageAbort = YES;
        return NO;
    }
    [NSURLConnection connectionWithRequest:request delegate:self];
    intentionalPageAbort = YES;
    return NO;
    
}

-(void)webViewDidStartLoad:(UIWebView*)webView {
	[activityIndicatorView startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [activityIndicatorView stopAnimating];
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (!intentionalPageAbort) {
        [activityIndicatorView stopAnimating];
        NSString* errorMsg = [error localizedDescription];
        [BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Identity Provider Error",@"\"Identity Provider Error\" alert message title")
                                     message:[NSString stringWithFormat:@"There was an error connecting to the identity provider: %@.  Please try again later.",errorMsg]
                                    delegate:self
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil];
    }
}

#pragma mark -
#pragma mark UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [[BlioStoreManager sharedInstance] loginFinishedForSourceID:BlioBookSourceOnlineStore];
}


@end
