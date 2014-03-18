//
//  BlioLoginService.m
//  StackApp
//
//  Created by Arnold Chien on 1/27/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import "BlioAccountService.h"
#import "BlioLoginService.h"
#import "BlioStoreHelper.h"
#import "MediaArcPlatform.h"

/*
@implementation BlioIdentityProvider
@synthesize name, loginURL, logoutURL; 
@end
 */

@implementation BlioLoginService

+(BlioLoginService*)sharedInstance {
    static BlioLoginService * sharedService = nil;
    if (sharedService == nil)
        sharedService = [[BlioLoginService alloc] init];
    return sharedService;
}

- (id)init
{
	self = [super init];
	if (self) {
        //
    }
	return self;
}

-(void)getIdentityProviders:(NSURLSession*)session {
    NSString* realmString = [[MediaArcPlatform sharedInstance].realmURL stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    NSString* url = [NSString stringWithFormat:
                     [MediaArcPlatform sharedInstance].providersURLFormat,
                     [MediaArcPlatform sharedInstance].acsNamespace,
                     [MediaArcPlatform sharedInstance].acsHost,
                     realmString];
    NSURLRequest *providersRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    NSURLSessionDataTask* task = [session dataTaskWithRequest:providersRequest];
    [task resume];
    [providersRequest release];
}

-(NSMutableArray*)getIdentityProvidersSync {
    NSString* realmString = [[MediaArcPlatform sharedInstance].realmURL stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    NSString* url = [NSString stringWithFormat:
                     [MediaArcPlatform sharedInstance].providersURLFormat,
                     [MediaArcPlatform sharedInstance].acsNamespace,
                     [MediaArcPlatform sharedInstance].acsHost,
                     realmString];
    NSURLRequest *providersRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    NSURLResponse* resp;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:providersRequest returningResponse:&resp error:nil];
    [providersRequest release];
    if (!responseData) {
        NSLog(@"Could not get identity providers.");
        return nil;
    }
    NSError* error;
    id jsonArray = [NSJSONSerialization
                          JSONObjectWithData:responseData
                          options:kNilOptions
                    error:&error];
    if (!jsonArray) {
        NSLog(@"Error: could not parse JSON for identity providers.");
        return nil;
    }
    if (![jsonArray isKindOfClass:[NSArray class]]) {
        NSLog(@"Error: JSON for identity providers is not an array.");
        return nil;
    }
    return (NSMutableArray*)jsonArray;
}

- (void)checkin {
    NSString* checkinURL = @"https://";
    checkinURL = [[checkinURL stringByAppendingString:[MediaArcPlatform sharedInstance].servicesHost] stringByAppendingString:[MediaArcPlatform sharedInstance].checkinURL];
    NSMutableURLRequest* checkinRequest = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:checkinURL]]
                                           autorelease];
    [checkinRequest setValue:[[BlioAccountService sharedInstance] getAuthorizationHeader] forHTTPHeaderField:@"Authorization"];
    [NSURLConnection sendAsynchronousRequest:checkinRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         if (!error) {
             NSError* err;
             id jsonDict = [NSJSONSerialization
                                       JSONObjectWithData:data
                                       options:kNilOptions
                                       error:&err];
             if (!jsonDict) {
                 NSLog(@"Could not parse JSON for checkin: %@", [err description]);
             }
             else if (![jsonDict isKindOfClass:[NSDictionary class]]) {
                 NSLog(@"Error: JSON for checkin is not a dictionary.");
             }
             else {
                 [BlioAccountService sharedInstance].username = [jsonDict objectForKey:@"Name"];
                 [BlioAccountService sharedInstance].email = [jsonDict objectForKey:@"Email"];
                 [BlioAccountService sharedInstance].handle = [jsonDict objectForKey:@"Handle"];
                 //[BlioAccountService sharedInstance].loginHost = [[NSURL URLWithString:[provider objectForKey:@"LoginUrl"]] host];
                 [BlioAccountService sharedInstance].loginHost = [jsonDict objectForKey:@"IdentityProviderDescription"];
                 [[BlioAccountService sharedInstance] saveAccountSettings];
                 return;
             }
         }
         else
             NSLog(@"Checkin error: %@",[error description]);
         [BlioAccountService sharedInstance].logoutUrl = nil;
     }];
}

@end
