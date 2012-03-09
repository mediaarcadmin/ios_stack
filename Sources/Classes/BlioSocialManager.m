//
//  BlioSocialManager.m
//  BlioApp
//
//  Created by Don Shin on 2/29/12.
//  Copyright (c) 2012 CrossComm, Inc. All rights reserved.
//

#import "BlioSocialManager.h"
#import "BlioStoreManager.h"
#import "BlioStoreHelper.h"
#import "BlioAlertManager.h"

@interface BlioSocialManager (PRIVATE)

-(void)shareBookToTwitter:(BlioBook*)aBook;
-(void)shareBookToFacebook:(BlioBook*)aBook;

@end

@implementation BlioSocialManager

@synthesize rootViewController, facebook;

+(BlioSocialManager*)sharedSocialManager
{
	static BlioSocialManager * _sharedSocialManager = nil;
	if (_sharedSocialManager == nil) {
		_sharedSocialManager = [[BlioSocialManager alloc] init];
	}
	
	return _sharedSocialManager;
}
-(void)dealloc {
    self.rootViewController = nil;
    [super dealloc];
}
+(BOOL)canSendTweet {
    return [TWTweetComposeViewController canSendTweet];
}
-(void)shareBook:(BlioBook*)aBook socialType:(BlioSocialType)socialType {
    if (_bookToBeShared) [_bookToBeShared release];
    _bookToBeShared = [aBook retain];
    switch (socialType) {
        case BlioSocialTypeTwitter:
            [self shareBookToTwitter:aBook];
            break;
        case BlioSocialTypeFacebook:
            [self shareBookToFacebook:aBook];
            break;
            
        default:
            break;
    }
}
-(void)shareBookToTwitter:(BlioBook*)aBook {
    
    NSString * storeURL = [[[BlioStoreManager sharedInstance] storeHelperForSourceID:[aBook.sourceID intValue]] storeURLWithSourceSpecificID:aBook.sourceSpecificID];
    if (!storeURL) storeURL = @"https://mobile.blioreader.com/";
    
    NSString *url = [NSString stringWithFormat:@"https://www.googleapis.com/urlshortener/v1/url?key=%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"googleAPIKey"]];
    NSLog(@"url: %@",url);
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod: @"POST" ];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setHTTPBody:[[NSString stringWithFormat:@"{\"longUrl\": \"%@\"}",storeURL] dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLResponse *resp;
    NSError *error = nil;
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&resp error:&error];
    [request release];
    
    NSString * shortenedURLString = nil;
    
    if (error) {
        NSLog(@"ERROR: NSURLConnection for URL shortener: %@",[error localizedDescription]);
    }
    else {
        NSError * jsonParsingError = nil;
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:returnData options:0 error:&jsonParsingError];
        if (jsonParsingError) {
            NSLog(@"ERROR: NSJSONSerialization: %@",[jsonParsingError localizedDescription]);
            NSString * dataString = [NSString stringWithUTF8String:[returnData bytes]];
            NSLog(@"dataString: %@",dataString);
        }
        else if ([responseDictionary objectForKey:@"id"]) shortenedURLString = [responseDictionary objectForKey:@"id"];
    }
    
    TWTweetComposeViewController *tweetViewController = [[[TWTweetComposeViewController alloc] init] autorelease];
    
    NSString * finalMessage = @"";
    if (aBook.title) finalMessage = aBook.title;
    if (shortenedURLString) finalMessage = [NSString stringWithFormat:@"%@ - %@",finalMessage,shortenedURLString];
    // Set the initial tweet text. See the framework for additional properties that can be set.
    [tweetViewController setInitialText:finalMessage];
    
    // Create the completion handler block.
    [tweetViewController setCompletionHandler:^(TWTweetComposeViewControllerResult result) {
        
        switch (result) {
            case TWTweetComposeViewControllerResultCancelled:
                // The cancel button was tapped. Do nothing besides dismissing modal.

                break;
            case TWTweetComposeViewControllerResultDone:
                // The tweet was sent.
                [BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Tweet Sent!",@"\"Tweet Sent!\" alert message title")
                                             message:NSLocalizedStringWithDefaultValue(@"TWEET_SENT_SUCCESSFULLY",nil,[NSBundle mainBundle],@"Your tweet message was sent successfully.",@"Alert message shown to end-user when a book is successfully shared via Twitter.")
                                            delegate:nil 
                                   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
                                   otherButtonTitles: nil];

                break;
            default:
                break;
        }
                
        // Dismiss the tweet composition view controller.
        [rootViewController dismissModalViewControllerAnimated:YES];
    }];
    
    // Present the tweet composition view controller modally.
    [rootViewController presentModalViewController:tweetViewController animated:YES];
}
-(void)shareBookToFacebook:(BlioBook*)aBook {
    
    NSString * storeURL = [[[BlioStoreManager sharedInstance] storeHelperForSourceID:[aBook.sourceID intValue]] storeURLWithSourceSpecificID:aBook.sourceSpecificID];
    if (!storeURL) storeURL = @"https://mobile.blioreader.com/";

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Setup facebook Single-Sign-On (SSO) - this needs to be done only once    
    if (facebook == nil) {
        if ([defaults objectForKey:@"FacebookObj"])
            self.facebook = [defaults objectForKey:@"FacebookObj"];
        else {
            // Authenticate application with facebook
            NSLog(@"FacebookAppID: %@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"FacebookAppID"]);
            self.facebook = [[[Facebook alloc] initWithAppId:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"FacebookAppID"] andDelegate:self] autorelease];
        }
    }
    
    if ([defaults objectForKey:@"FBAccessTokenKey"] 
        && [defaults objectForKey:@"FBExpirationDateKey"]) {
        facebook.accessToken = [defaults objectForKey:@"FBAccessTokenKey"];
        facebook.expirationDate = [defaults objectForKey:@"FBExpirationDateKey"];
    }	
    
	if (![facebook isSessionValid]) {
        [facebook authorize:[NSArray arrayWithObject: @"publish_stream"]];
    }
    else {        
        NSLog(@"storeURL: %@",storeURL);
        NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       NSLocalizedString(@"Share on Facebook",@"\"Share on Facebook\" message prompt"),  @"user_message_prompt",
                                       storeURL, @"link",
                                       nil];
        
        // Dialog to post on wall
        [facebook dialog:@"feed" andParams:params andDelegate:self];
    }
}

#pragma mark -
#pragma mark FBSessionDelegate Methods

- (void)fbDidLogin 
{
    
    NSString * storeURL = [[[BlioStoreManager sharedInstance] storeHelperForSourceID:[_bookToBeShared.sourceID intValue]] storeURLWithSourceSpecificID:_bookToBeShared.sourceSpecificID];
    if (!storeURL) storeURL = @"https://mobile.blioreader.com/";

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults setObject:facebook forKey:@"FacebookObj"];
    [defaults synchronize];
    
    // Dialog to post on wall
    NSLog(@"storeURL: %@",storeURL);
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   NSLocalizedString(@"Share on Facebook",@"\"Share on Facebook\" message prompt"),  @"user_message_prompt",
                                   storeURL, @"link",
                                   nil];
    
    // Dialog to post on wall
    [facebook dialog:@"feed" andParams:params andDelegate:self];    
}
-(void)facebookDialog:(NSArray*)actionAndParams {
    NSString * action = [actionAndParams objectAtIndex:0];
    NSMutableDictionary * params = [actionAndParams objectAtIndex:1];
    [facebook dialog:action andParams:params andDelegate:self];
}
- (void)fbDidLogout
{
    
}
- (void)fbDidExtendToken:(NSString*)accessToken
               expiresAt:(NSDate*)expiresAt {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:accessToken forKey:@"FBAccessTokenKey"];
    [defaults synchronize];
}

- (void) fbDidNotLogin:(BOOL)cancelled
{
    NSLog(@"did not login");
}
-(void) fbSessionInvalidated {
    
}

#pragma mark -
#pragma mark FBDialogDelegate Methods

/**
 * Called when the dialog succeeds and is about to be dismissed.
 */
- (void)dialogDidComplete:(FBDialog *)dialog {
    
}

/**
 * Called when the dialog succeeds with a returning url.
 */
- (void)dialogCompleteWithUrl:(NSURL *)url {
    
}

/**
 * Called when the dialog get canceled by the user.
 */
- (void)dialogDidNotCompleteWithUrl:(NSURL *)url {
    
}

/**
 * Called when the dialog is cancelled and is about to be dismissed.
 */
- (void)dialogDidNotComplete:(FBDialog *)dialog {
    
}

/**
 * Called when dialog failed to load due to an error.
 */
- (void)dialog:(FBDialog*)dialog didFailWithError:(NSError *)error {
    //  1st time dialog shows up blank due to NSURLErrorDomain error -999. Possible race condition? 
    //  see http://stackoverflow.com/questions/8002260/first-dialog-after-authenticating-fails-immediately-and-closes-dialog

    // workaround
    if([error code] == -999){
        NSLog(@"Error -999 found re-open webview");
        
        [facebook dialog:@"feed"
               andParams:dialog.params
             andDelegate:self];
        
    }else{
        NSLog(@"Facebook ERROR: %@",[error localizedDescription]);
    }
}

/**
 * Asks if a link touched by a user should be opened in an external browser.
 *
 * If a user touches a link, the default behavior is to open the link in the Safari browser,
 * which will cause your app to quit.  You may want to prevent this from happening, open the link
 * in your own internal browser, or perhaps warn the user that they are about to leave your app.
 * If so, implement this method on your delegate and return NO.  If you warn the user, you
 * should hold onto the URL and once you have received their acknowledgement open the URL yourself
 * using [[UIApplication sharedApplication] openURL:].
 */
- (BOOL)dialog:(FBDialog*)dialog shouldOpenURLInExternalBrowser:(NSURL *)url {
    return YES;  
}

@end
