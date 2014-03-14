 //
//  BlioAccountService.m
//  StackApp
//
//  Created by Arnold Chien on 2/4/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import "BlioAccountService.h"
#import "BlioAppSettingsConstants.h"
#import "BlioStoreHelper.h"

@implementation BlioAccountService

@synthesize username, email, handle, provider, loginHost, logoutUrl;

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

-(void)retrieveAccountSettings {
    NSDictionary* accountDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kBlioAccountSettingsDefaultsKey];
    self.username = [accountDict valueForKey:@"username"];
    self.email = [accountDict objectForKey:@"email"];
    self.handle = [accountDict objectForKey:@"handle"];
    self.loginHost = [accountDict objectForKey:@"loginHost"];
    self.logoutUrl = [accountDict objectForKey:@"logoutUrl"];
}

-(void)saveAccountSettings {
    NSMutableDictionary * accountDict = [NSMutableDictionary dictionaryWithCapacity:5];
    if (self.username && (![self.username isEqual:[NSNull null]]))
        [accountDict setValue:self.username forKey:@"username"];
    if (self.email && (![self.email isEqual:[NSNull null]]))
        [accountDict setValue:self.email forKey:@"email"];
    if (self.handle && (![self.handle isEqual:[NSNull null]]))
        [accountDict setValue:self.handle forKey:@"handle"];
    if (self.loginHost && (![self.loginHost isEqual:[NSNull null]]))
        [accountDict setValue:self.loginHost forKey:@"loginHost"];
    if (self.logoutUrl && (![self.logoutUrl isEqual:[NSNull null]]))
        [accountDict setValue:self.logoutUrl forKey:@"logoutUrl"];
    [[NSUserDefaults standardUserDefaults] setObject:accountDict forKey:kBlioAccountSettingsDefaultsKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)logout {
    if (self.logoutUrl) {
        NSMutableURLRequest* logoutRequest = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.logoutUrl]]
                                               autorelease];
        [NSURLConnection sendAsynchronousRequest:logoutRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
            {
                if (error)
                    NSLog(@"There was a logout error: %@", [error description]);
                    // But we count logout as successful anyway
                //else  {
                        // TODO?  Should we analyze anything in the response?
                        //NSString *responseString = [[NSString alloc] initWithData:responseData encoding: NSUTF8StringEncoding];
                //}
                self.username = nil;
                self.email = nil;
                self.handle = nil;
                self.loginHost = nil;
                self.logoutUrl = nil;
                [self saveAccountSettings];
            }];
    }
    // else get oem-specific url?
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
    NSString* token = [[BlioStoreManager sharedInstance] tokenForSourceID:BlioBookSourceOnlineStore];
    if (!token)
        return nil;
    return [NSString stringWithFormat:@"OAuth2 access_token=\"%@\"",token];
}

@end
