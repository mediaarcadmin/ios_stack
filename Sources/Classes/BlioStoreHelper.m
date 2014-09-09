//
//  BlioStoreHelper.m
//  BlioApp
//
//  Created by Don Shin on 5/7/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import "BlioStoreHelper.h"
#import "BlioAccountService.h"

@implementation BlioStoreHelper

@synthesize delegate, timeout, token, sourceID, storeTitle, siteID, siteKey, userNum, isRetrievingBooks,downloadNewBooks,forceLoginDisplayUponFailure;

-(void) dealloc {
	self.storeTitle = nil;
	self.siteKey = nil;
	self.token = nil;
	self.timeout = nil;
    [[BlioStoreManager sharedInstance] saveToken];
	[super dealloc];
}

-(void)buyBookWithSourceSpecificID:(NSString*)sourceSpecificID {
	// abstract method	
}

-(NSString*)storeURLWithSourceSpecificID:(NSString*)sourceSpecificID {
	// abstract method	
    return nil;
}

- (void)logout {
	// abstract method	
	
}
-(BOOL)hasValidToken {
	// abstract method	
	return NO;
}

-(BOOL)isLoggedIn {
	return [self hasValidToken];
}

-(NSString*)loginHostname {
	return nil;
}

-(NSString*)username {
	if ([self isLoggedIn])
        return [[BlioAccountService sharedInstance] username];
	else return nil;
}

-(BlioDeviceRegisteredStatus)deviceRegistered {
	// abstract method	
	return BlioDeviceRegisteredStatusUndefined;
}

-(BOOL) setDeviceRegisteredSettingOnly:(BlioDeviceRegisteredStatus)targetStatus {
	return NO;
}

-(BOOL)setDeviceRegistered:(BlioDeviceRegisteredStatus)status {
	// abstract method	
	return NO;
}

-(void)retrieveMedia {
	// abstract method	
}

-(NSURL*)URLForProductWithID:(NSString*)stringID {
	// abstract method	
	return nil;
}

-(NSURL*)URLForSongWithID:(NSString*)stringID {
	// abstract method
	return nil;
}

@end
