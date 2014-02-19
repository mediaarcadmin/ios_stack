 //
//  BlioAccountService.m
//  StackApp
//
//  Created by Arnold Chien on 2/4/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import "BlioAccountService.h"
#import "BlioStoreHelper.h"

@implementation BlioAccountService

@synthesize token, username, email, handle, provider, loginHost, logoutUrl;

+(BlioAccountService*)sharedInstance {
    static BlioAccountService * sharedService = nil;
    if (sharedService == nil)
        sharedService = [[BlioAccountService alloc] init];
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

-(void)logout {
    if (self.logoutUrl) {
        NSMutableURLRequest* logoutRequest = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.logoutUrl]]
                                               autorelease];
        NSError* err;
        NSData *responseData = [NSURLConnection sendSynchronousRequest:logoutRequest returningResponse:nil error:&err];
        if (responseData) {
            // TODO?  Should we analyze anything in the response?
            //NSString *responseString = [[NSString alloc] initWithData:responseData encoding: NSUTF8StringEncoding];
            [BlioAccountService sharedInstance].username = nil;
            [BlioAccountService sharedInstance].email = nil;
            [BlioAccountService sharedInstance].handle = nil;
            [BlioAccountService sharedInstance].loginHost = nil;
            [[BlioStoreManager sharedInstance] logoutForSourceID:BlioBookSourceOnlineStore];
        }
    }
    // else get oem-specific url?
    
    // TODO alert
    NSLog(@"Could not log out.");
}

-(NSString*)getAccountID {
    NSString* user = [BlioAccountService sharedInstance].username;
    NSString* addr;
    NSString* ip = [BlioAccountService sharedInstance].loginHost;
    if (user && (user != (id)[NSNull null]))
        return user;
    else if ((addr = [BlioAccountService sharedInstance].email) &&
             (addr != (id)[NSNull null]))
        return addr;
    else if ((ip = [BlioAccountService sharedInstance].loginHost) &&
             (ip != (id)[NSNull null]))
        return ip;
    else
        return @"Logged in.";
}

-(NSString*)getAuthorizationHeader {
    if (!self.token)
        return nil;
    return [NSString stringWithFormat:@"OAuth2 access_token=\"%@\"",self.token.securityToken];
}

@end
