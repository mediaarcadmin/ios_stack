//
//  BlioStoreHelper.h
//  BlioApp
//
//  Created by Don Shin on 5/7/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioStoreHelperDelegate.h"
#import "BlioProcessing.h"
#import "BlioStoreManager.h"

@interface BlioStoreHelper : NSObject {
	BOOL isLoggedIn;
	NSString* username;
	NSString* token;
	NSDate* timeout;
	NSString* storeTitle;
	BlioBookSourceID sourceID;
	id<BlioStoreHelperDelegate> delegate;
	
}
@property (nonatomic, retain) NSDate* timeout;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *storeTitle;
@property (nonatomic, assign) id<BlioStoreHelperDelegate> delegate;
@property (nonatomic) BOOL isLoggedIn;
@property (nonatomic) BlioBookSourceID sourceID;

- (void)loginWithUsername:(NSString*)user password:(NSString*)password;
- (void)logout;
-(BOOL)hasValidToken;
-(BlioDeviceRegisteredStatus)deviceRegistered;
-(void)setDeviceRegistered:(BlioDeviceRegisteredStatus)status;
-(void)retrieveBooks;
-(NSURL*)URLForBookWithID:(NSString*)stringID;
@end
