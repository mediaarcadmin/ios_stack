//
//  BlioLoginService.m
//  StackApp
//
//  Created by Arnold Chien on 1/27/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import "BlioLoginService.h"
#import "MediaArcPlatform.h"

@implementation BlioIdentityProvider
@synthesize name, loginURL, logoutURL; //, command;
@end

@implementation BlioLoginService
@synthesize serverPart, checkinPart;

- (id)init
{
	self = [super init];
	if (self) {
		self.serverPart = @"https://";
        [self.serverPart stringByAppendingString:[MediaArcPlatform sharedInstance].servicesHost];
        self.checkinPart = @"/api/user";
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
    NSData *responseData = [NSURLConnection sendSynchronousRequest:providersRequest returningResponse:nil error:nil];
    [providersRequest release];
    NSError* error;
    NSMutableArray* jsonArray = [NSJSONSerialization
                          JSONObjectWithData:responseData
                          options:kNilOptions
                          error:&error];
    return jsonArray;
}

-(NSString*)getSWTToken:(NSString*)loginResponse {
    return nil;
}

- (void)checkin:(NSString*)host identityProvider:(NSString*)provider {
    return;
}

@end
