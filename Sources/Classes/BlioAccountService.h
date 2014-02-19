//
//  BlioAccountService.h
//  StackApp
//
//  Created by Arnold Chien on 2/4/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WACloudAccessToken.h"

@interface BlioAccountService : NSObject {
    const NSString* supportTokenURL;
}

@property (nonatomic, retain) WACloudAccessToken* token;
@property (nonatomic, retain) NSString* username;
@property (nonatomic, retain) NSString* email;
@property (nonatomic, retain) NSString* handle;
@property (nonatomic, retain) NSDictionary* provider;
@property (nonatomic, retain) NSString* loginHost;
@property (nonatomic, retain) NSString* logoutUrl;

+(BlioAccountService*)sharedInstance;

-(NSString*)getAuthorizationHeader;
-(NSString*)getAccountID;
-(void)logout;

@end
