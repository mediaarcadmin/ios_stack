//
//  BlioStoreHelper.m
//  BlioApp
//
//  Created by Don Shin on 5/7/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import "BlioStoreHelper.h"


@implementation BlioStoreHelper

@synthesize delegate, timeout, token, sourceID, storeTitle,isRetrievingBooks;

-(void) dealloc {
	if (username) [username release];
	self.token = nil;
	self.timeout = nil;
	self.storeTitle = nil;
	[super dealloc];
}

- (void)loginWithUsername:(NSString*)user password:(NSString*)password {
	// abstract method	
	
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
-(NSString*)username {
	if ([self isLoggedIn]) return username;
	else return nil;
}
-(BlioDeviceRegisteredStatus)deviceRegistered {
	// abstract method	
	return BlioDeviceRegisteredStatusUndefined;
}
-(BOOL)setDeviceRegistered:(BlioDeviceRegisteredStatus)status {
	// abstract method	
	return NO;
}
-(void)retrieveBooks {
	// abstract method	
}
-(NSURL*)URLForBookWithID:(NSString*)stringID {
	// abstract method	
	return nil;
}
@end
