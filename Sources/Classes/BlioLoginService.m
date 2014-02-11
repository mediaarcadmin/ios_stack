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

-(NSMutableArray*)getIdentityProviders {
    NSString* realmString = [[MediaArcPlatform sharedInstance].realmURL stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    NSString* url = [NSString stringWithFormat:@"https://%@.%@/v2/metadata/IdentityProviders.js?protocol=javascriptnotify&realm=%@&version=1.0",
                     [MediaArcPlatform sharedInstance].acsNamespace,
                     [MediaArcPlatform sharedInstance].acsHost,
                     realmString];
    NSURLRequest *providersRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    NSURLResponse* resp;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:providersRequest returningResponse:&resp error:nil];
    [providersRequest release];
    NSError* error;
    NSMutableArray* jsonArray = [NSJSONSerialization
                          JSONObjectWithData:responseData
                          options:kNilOptions
                          error:&error];
    return jsonArray;
}

- (void)checkin:(NSDictionary*)provider {
    NSString* checkinURL = @"https://";
    checkinURL = [[checkinURL stringByAppendingString:[MediaArcPlatform sharedInstance].servicesHost] stringByAppendingString:@"/api/user"];
    NSMutableURLRequest* checkinRequest = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:checkinURL]]
                                           autorelease];
    [checkinRequest setValue:[[BlioAccountService sharedInstance] getAuthorizationHeader] forHTTPHeaderField:@"Authorization"];
    NSError* err;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:checkinRequest returningResponse:nil error:&err];
    if (responseData) {
        NSDictionary* jsonDict = [NSJSONSerialization
                                     JSONObjectWithData:responseData
                                     options:kNilOptions
                                     error:&err];
        if (jsonDict) {
            [BlioAccountService sharedInstance].username = [jsonDict objectForKey:@"Name"];
            [BlioAccountService sharedInstance].email = [jsonDict objectForKey:@"Email"];
            [BlioAccountService sharedInstance].handle = [jsonDict objectForKey:@"Handle"];
            //[BlioAccountService sharedInstance].loginHost = [[NSURL URLWithString:[provider objectForKey:@"LoginUrl"]] host];
            [BlioAccountService sharedInstance].loginHost = [jsonDict objectForKey:@"IdentityProvider"];
            BlioStoreHelper* helper = [[BlioStoreManager sharedInstance] storeHelperForSourceID:BlioBookSourceOnlineStore];
            helper.token =  [BlioAccountService sharedInstance].token.securityToken;
            helper.timeout = [[BlioAccountService sharedInstance].token expireDate];
            [[BlioStoreManager sharedInstance] loginFinishedForSourceID:helper.sourceID];
            return;
        }
    }
    [BlioAccountService sharedInstance].token = nil;
    NSLog(@"Checkin error: %@",[err description]);
    // TODO alert
}

@end
