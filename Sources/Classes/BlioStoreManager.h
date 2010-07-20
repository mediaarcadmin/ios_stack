//
//  BlioStoreManager.h
//  BlioApp
//
//  Created by Don Shin on 5/7/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioStoreHelperDelegate.h"
#import "BlioProcessing.h"

@class BlioLoginViewController;

typedef enum  {
	BlioLoginResultSuccess = 0,
    BlioLoginResultInvalidPassword,
    BlioLoginResultError,
} BlioLoginResult;

typedef enum  {
	BlioDeviceRegisteredStatusUnregistered = -1,
    BlioDeviceRegisteredStatusUndefined = 0,
    BlioDeviceRegisteredStatusRegistered = 1,
} BlioDeviceRegisteredStatus;

static NSString * const BlioLoginFinished = @"BlioLoginFinished";

@interface BlioStoreManager : NSObject<BlioStoreHelperDelegate> {
	BOOL isShowingLoginView;
	NSMutableDictionary * storeHelpers;
	NSMutableDictionary * deviceRegistrationPromptAlertViews;
	UIViewController * rootViewController;
	BlioLoginViewController *loginViewController;
    id<BlioProcessingDelegate> _processingDelegate;
}

@property (nonatomic, retain) NSMutableDictionary* storeHelpers;
@property (nonatomic, retain) NSMutableDictionary* deviceRegistrationPromptAlertViews;
@property (nonatomic, retain) UIViewController* rootViewController;
@property (nonatomic, retain) BlioLoginViewController* loginViewController;
@property (nonatomic) BOOL isShowingLoginView;
@property (nonatomic, assign) id<BlioProcessingDelegate> processingDelegate;

+(BlioStoreManager*)sharedInstance;
-(void)loginWithUsername:(NSString*)user password:(NSString*)password sourceID:(BlioBookSourceID)sourceID;
-(BlioStoreHelper*)storeHelperForSourceID:(BlioBookSourceID)sourceID;
-(void)requestLoginForSourceID:(BlioBookSourceID)sourceID;
-(void)showLoginViewForSourceID:(BlioBookSourceID)sourceID;
-(BOOL)isLoggedInForSourceID:(BlioBookSourceID)sourceID;
-(void)retrieveBooksForSourceID:(BlioBookSourceID)sourceID;
- (NSString*)tokenForSourceID:(BlioBookSourceID)sourceID;
-(void)logoutForSourceID:(BlioBookSourceID)sourceID;
-(void)loginFinishedForSourceID:(BlioBookSourceID)sourceID;
-(void)setStoreHelper:(BlioStoreHelper*)helper;
-(NSString*)storeTitleForSourceID:(BlioBookSourceID)sourceID;
-(NSURL*)URLForBookWithSourceID:(BlioBookSourceID)sourceID sourceSpecificID:(NSString*)sourceSpecificID;
@end
