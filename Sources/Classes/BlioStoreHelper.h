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
	NSString* token;
	NSDate* timeout;
	NSString* storeTitle;
	BlioBookSourceID sourceID;
	id<BlioStoreHelperDelegate> delegate;
	BOOL isRetrievingBooks;
	BOOL downloadNewBooks;
	NSInteger siteID;
	NSString* siteKey;
	NSInteger userNum;
	BOOL forceLoginDisplayUponFailure;
}
@property (nonatomic, retain) NSDate* timeout;
@property (nonatomic, readonly) NSString *username;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *storeTitle;
@property (nonatomic, assign) id<BlioStoreHelperDelegate> delegate;
@property (nonatomic) BlioBookSourceID sourceID;
@property (nonatomic, readonly) BOOL isRetrievingBooks;
@property (nonatomic, assign) BOOL downloadNewBooks;
@property (nonatomic, assign) NSInteger siteID;
@property (nonatomic, retain) NSString *siteKey;
@property (nonatomic, assign) NSInteger userNum;
@property (nonatomic, assign) BOOL forceLoginDisplayUponFailure;

-(void)buyBookWithSourceSpecificID:(NSString*)sourceSpecificID;
-(NSString*)storeURLWithSourceSpecificID:(NSString*)sourceSpecificID;
- (void)logout;
-(BOOL)hasValidToken;
-(BOOL)isLoggedIn;
-(NSString*)loginHostname;
-(BlioDeviceRegisteredStatus)deviceRegistered;
-(BOOL) setDeviceRegisteredSettingOnly:(BlioDeviceRegisteredStatus)targetStatus;
-(BOOL)setDeviceRegistered:(BlioDeviceRegisteredStatus)status;
-(void)retrieveMedia;
-(NSURL*)URLForProductWithID:(NSString*)stringID;
@end
