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
static NSString * const BlioStoreRetrieveBooksStarted = @"BlioStoreRetrieveBooksStarted";
static NSString * const BlioStoreRetrieveBooksFinished = @"BlioStoreRetrieveBooksFinished";


@interface BlioStoreManager : NSObject<BlioStoreHelperDelegate> {
	BOOL isShowingLoginView;
	NSMutableDictionary * storeHelpers;
	NSMutableDictionary * deviceRegistrationPromptAlertViews;
	UIViewController * rootViewController;
	BlioLoginViewController *loginViewController;
    id<BlioProcessingDelegate> _processingDelegate;
	BlioStoreHelper * currentStoreHelper;
}

@property (nonatomic, retain) NSMutableDictionary* storeHelpers;
@property (nonatomic, retain) NSMutableDictionary* deviceRegistrationPromptAlertViews;
@property (nonatomic, retain) UIViewController* rootViewController;
@property (nonatomic, retain) BlioLoginViewController* loginViewController;
@property (nonatomic) BOOL isShowingLoginView;
@property (nonatomic, assign) id<BlioProcessingDelegate> processingDelegate;
@property (nonatomic, retain) BlioStoreHelper * currentStoreHelper;

/**
	Returns the shared BlioStoreManager instance.
 @returns The shared BlioStoreManager instance.
 */
+(BlioStoreManager*)sharedInstance;
-(void)saveUsername:(NSString*)user password:(NSString*)password sourceID:(BlioBookSourceID)sourceID;
-(void)saveRegistrationAccountID:(NSString*)accountID serviceID:(NSString*)serviceID;
-(NSDictionary*)registrationRecords;
/**
 Passes the request to login with the included credentials to the appropriate store helper.
 @param user The username for the login request (usually the email address).
 @param password The password for the login request.
 @param sourceID The BlioBookSourceID for which login has been requested.
 */
-(void)loginWithUsername:(NSString*)user password:(NSString*)password sourceID:(BlioBookSourceID)sourceID;
/**
	Returns the store helper associated with the given BlioBookSourceID.
	@param sourceID The BlioBookSourceID by which the store helper should be identified.
	@returns A BlioStoreHelper associated with the given BlioBookSourceID; if no BlioStoreHelper is associated, then nil is returned.
 */
-(BlioStoreHelper*)storeHelperForSourceID:(BlioBookSourceID)sourceID;
/**
	Attempts login using stored credentials. If no stored credentials are found for given sourceID, then login view is shown.
	@param sourceID The BlioBookSourceID for the login request.
 */
-(void)requestLoginForSourceID:(BlioBookSourceID)sourceID;
/**
	Shows login view modally; input from the login view fields are then used to login for the given sourceID.
	@param sourceID The BlioBookSourceID to be used when the end-user attempts to login.
 */
-(void)showLoginViewForSourceID:(BlioBookSourceID)sourceID;
/**
	Returns a boolean login status indicated whether or not the manager is logged in for the given sourceID.
	@param sourceID The BlioBookSourceID for which the login status is related.
	@returns The login status.
 */
-(BOOL)isLoggedInForSourceID:(BlioBookSourceID)sourceID;
/**
	Asynchronously retrieves books (by source-specific ID/ISBN) from the appropriate store helper associated with the given sourceID.
	@param sourceID The BlioBookSourceID for which books should be retrieved.
 */
-(NSString*)usernameForSourceID:(BlioBookSourceID)sourceID;
-(void)retrieveBooksForSourceID:(BlioBookSourceID)sourceID;
/**
	Returns a valid token for a given sourceID. If no valid token is available, then nil is returned.
	@param sourceID The BlioBookSourceID associated with the prospective token requested.
	@returns The token as NSString if available and valid; otherwise nil is returned.
 */
- (NSString*)tokenForSourceID:(BlioBookSourceID)sourceID;
/**
	Discards token for given sourceID; however, the login credentials (i.e. username and password) are not necessarily forgotten.
	@param sourceID The BlioBookSourceID for which logout should occur.
 */
-(void)logoutForSourceID:(BlioBookSourceID)sourceID;
/**
	This method is used to communicate to the BlioStoreManager that the login process has finished for a given sourceID; this usually happens when a login view is dismissed or a login is accomplished with credentials. The method performs any necessary clean-up operations and is responsible for broadcasting a notification indicating to any interested listeners that the login process has finished for a particular sourceID.
	@param sourceID The BlioBookSourceID for which the login process has finished.
 */
-(void)loginFinishedForSourceID:(BlioBookSourceID)sourceID;
/**
	Adds a given store helper to the BlioStoreManager's dictionary of store helpers.
	@param helper The store helper to be added.
 */
-(void)addStoreHelper:(BlioStoreHelper*)helper;
/**
	Returns the title of the store that handles the given sourceID.
	@param sourceID The BlioBookSourceID used to determine which store's title should be returned.
	@returns The title as an NSString object.
 */
-(NSString*)storeTitleForSourceID:(BlioBookSourceID)sourceID;
-(NSInteger)currentUserNum;
-(NSInteger)currentSiteNum;
-(NSInteger)storeSiteIDForSourceID:(BlioBookSourceID)sourceID;
-(NSString*)storeSiteKeyForSourceID:(BlioBookSourceID)sourceID;
-(NSDictionary*)savedLoginCredentials;
/**
	Synchronously retrieves the URL for a book identified by a source-specific ID from the appropriate store helper.
	@param sourceID The BlioBookSourceID of the book.
	@param sourceSpecificID The source-specific ID of the book.
	@returns An NSURL pointing to the book asset.
 */
-(NSURL*)URLForBookWithSourceID:(BlioBookSourceID)sourceID sourceSpecificID:(NSString*)sourceSpecificID;
-(void)dismissLoginView;
-(BlioDeviceRegisteredStatus)deviceRegisteredForSourceID:(BlioBookSourceID)sourceID;
-(BOOL)setDeviceRegisteredSettingOnly:(BlioDeviceRegisteredStatus)status forSourceID:(BlioBookSourceID)sourceID;
-(BOOL)setDeviceRegistered:(BlioDeviceRegisteredStatus)status forSourceID:(BlioBookSourceID)sourceID;
@end
