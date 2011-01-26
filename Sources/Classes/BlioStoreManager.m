//
//  BlioStoreManager.m
//  BlioApp
//
//  Created by Don Shin on 5/7/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import "BlioStoreManager.h"
#import "BlioOnlineStoreHelper.h"
#import "BlioLoginViewController.h"
#import "BlioAlertManager.h"
#import "BlioDrmSessionManager.h"
#import "BlioAppSettingsConstants.h"
#import "BlioCreateAccountViewController.h"
#import "BlioWelcomeViewController.h"
#import "SFHFKeychainUtils.h"

@implementation BlioStoreManager

@synthesize storeHelpers, isShowingLoginView, rootViewController,loginViewController,deviceRegistrationPromptAlertViews,currentStoreHelper,initialLoginCheckFinished;
@synthesize processingDelegate = _processingDelegate;

+(BlioStoreManager*)sharedInstance
{
	static BlioStoreManager * sharedStoreManager = nil;
	if (sharedStoreManager == nil) {
		sharedStoreManager = [[BlioStoreManager alloc] init];
	}
	
	return sharedStoreManager;
}

- (id) init {
	if((self = [super init])) {
		self.storeHelpers = [NSMutableDictionary dictionaryWithCapacity:1];
		self.deviceRegistrationPromptAlertViews = [NSMutableDictionary dictionaryWithCapacity:1];
		[self addStoreHelper:[[[BlioOnlineStoreHelper alloc] init] autorelease]];
		initialLoginCheckFinished = NO;
	}
	return self;
}

-(void) dealloc {
	self.storeHelpers = nil;
	self.deviceRegistrationPromptAlertViews = nil;
	self.rootViewController = nil;
	self.loginViewController = nil;
	[super dealloc];
}

-(void)addStoreHelper:(BlioStoreHelper*)helper {
	helper.delegate = self;
	[storeHelpers setObject:helper forKey:[NSNumber numberWithInt:helper.sourceID]];
	if (!currentStoreHelper) self.currentStoreHelper = helper;
}
-(BOOL)didOpenWebStore {
	return [[NSUserDefaults standardUserDefaults] boolForKey:kBlioDidOpenWebStoreDefaultsKey];
}
-(void)setDidOpenWebStore:(BOOL)boolValue {
	[[NSUserDefaults standardUserDefaults] setBool:boolValue forKey:kBlioDidOpenWebStoreDefaultsKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}
-(NSString*)currentStoreURL {
	return self.currentStoreHelper.storeURL;
}
-(void)openCurrentWebStore {
	self.didOpenWebStore = YES;
	NSURL* url = [NSURL URLWithString:[self currentStoreURL]];
	[[UIApplication sharedApplication] openURL:url];			  
}
-(void)buyBookWithSourceSpecificID:(NSString*)sourceSpecificID {
	[self.currentStoreHelper buyBookWithSourceSpecificID:sourceSpecificID];
}
-(void)requestLoginForSourceID:(BlioBookSourceID)sourceID {
	[self requestLoginForSourceID:sourceID forceLoginDisplayUponFailure:NO];
}
-(void)requestLoginForSourceID:(BlioBookSourceID)sourceID forceLoginDisplayUponFailure:(BOOL)forceLoginDisplay {
	// first check to see if login info is in NSUserDefaults
	
	NSDictionary * loginCredentials = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kBlioUserLoginCredentialsDefaultsKey];
	if ([loginCredentials objectForKey:@"username"]) {
		NSError * error = nil;
		NSString * password = [SFHFKeychainUtils getPasswordForUsername:[loginCredentials objectForKey:@"username"] andServiceName:kBlioUserLoginCredentialsDefaultsKey error:&error];
		if (!error && password) {
			[[BlioStoreManager sharedInstance] storeHelperForSourceID:sourceID].forceLoginDisplayUponFailure = forceLoginDisplay;
			[[BlioStoreManager sharedInstance] loginWithUsername:[loginCredentials objectForKey:@"username"] password:password sourceID:sourceID];
		}
		else {
			if (error) NSLog(@"ERROR: obtaining password from SFHFKeychainUtils with username %@: %@",[loginCredentials objectForKey:@"username"],[error localizedDescription]);
			[[BlioStoreManager sharedInstance] showLoginViewForSourceID:sourceID];
		}
	}
	else {
		[[BlioStoreManager sharedInstance] showLoginViewForSourceID:sourceID];
	}
}
-(BlioStoreHelper*)storeHelperForSourceID:(BlioBookSourceID)sourceID {
	for (id key in self.storeHelpers) {
		if ([key intValue] == sourceID) return (BlioStoreHelper*)[self.storeHelpers objectForKey:key]; 
	}
	return nil;
}
-(NSString*)storeTitleForSourceID:(BlioBookSourceID)sourceID {
	for (id key in self.storeHelpers) {
		if ([key intValue] == sourceID) return ((BlioStoreHelper*)[self.storeHelpers objectForKey:key]).storeTitle; 
	}
	return nil;
}
-(NSString*)storeSiteKeyForSourceID:(BlioBookSourceID)sourceID {
	for (id key in self.storeHelpers) {
		if ([key intValue] == sourceID) return ((BlioStoreHelper*)[self.storeHelpers objectForKey:key]).siteKey; 
	}
	return nil;
}
-(NSInteger)currentSiteNum {
	return self.currentStoreHelper.siteID;
}
-(NSInteger)storeSiteIDForSourceID:(BlioBookSourceID)sourceID {
	for (id key in self.storeHelpers) {
		if ([key intValue] == sourceID) return ((BlioStoreHelper*)[self.storeHelpers objectForKey:key]).siteID; 
	}
	return -1;
}
-(NSInteger)currentUserNum {
	return self.currentStoreHelper.userNum;
}
-(void)showWelcomeViewForSourceID:(BlioBookSourceID)sourceID {
	self.loginViewController = [[[BlioWelcomeViewController alloc] initWithSourceID:sourceID] autorelease];
	UINavigationController * modalLoginNavigationController = [[[UINavigationController alloc] initWithRootViewController:loginViewController] autorelease];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		modalLoginNavigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		modalLoginNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	[((UINavigationController*)rootViewController).visibleViewController presentModalViewController:modalLoginNavigationController animated:YES];
	isShowingLoginView = YES;	
}
-(void)showLoginViewForSourceID:(BlioBookSourceID)sourceID {
	self.loginViewController = [[[BlioLoginViewController alloc] initWithSourceID:sourceID] autorelease];
	
	UINavigationController * modalLoginNavigationController = [[[UINavigationController alloc] initWithRootViewController:loginViewController] autorelease];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		modalLoginNavigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		modalLoginNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	
	[((UINavigationController*)rootViewController).visibleViewController presentModalViewController:modalLoginNavigationController animated:YES];
	isShowingLoginView = YES;	
}
-(void)showCreateAccountViewForSourceID:(BlioBookSourceID)sourceID {
	self.loginViewController = [[[BlioCreateAccountViewController alloc] initWithSourceID:sourceID] autorelease];
	
//	self.loginViewController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] 
//											   initWithTitle:NSLocalizedString(@"Cancel",@"\"Cancel\" bar button") 
//											   style:UIBarButtonItemStyleDone 
//											   target:self
//											   action:@selector(dismissLoginView)]
//											  autorelease];
	
	UINavigationController * modalLoginNavigationController = [[[UINavigationController alloc] initWithRootViewController:loginViewController] autorelease];
	
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		modalLoginNavigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		modalLoginNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
	}
#endif	
	
	[((UINavigationController*)rootViewController).visibleViewController presentModalViewController:modalLoginNavigationController animated:YES];
	isShowingLoginView = YES;	
}
-(void)dismissLoginView {
	[((UINavigationController*)rootViewController).visibleViewController dismissModalViewControllerAnimated:YES];
}
-(void)loginFinishedForSourceID:(BlioBookSourceID)sourceID {
	isShowingLoginView = NO;
	self.loginViewController = nil;
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
	[userInfo setValue:[NSNumber numberWithInt:sourceID] forKey:@"sourceID"];
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioLoginFinished object:self userInfo:userInfo];

}
-(void)saveUsername:(NSString*)username {
	NSString * oldUsername = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:kBlioUserLoginCredentialsDefaultsKey] objectForKey:@"username"];
	if (oldUsername && ![oldUsername isEqualToString:username]) {
		NSError * error = nil;
		[SFHFKeychainUtils deleteItemForUsername:oldUsername andServiceName:kBlioUserLoginCredentialsDefaultsKey error:&error];
		if (error) {
			NSLog(@"ERROR: deleting login credentials and password for old username %@: %@",[error localizedDescription]);
		}
	}
	NSMutableDictionary * loginCredentials = [NSMutableDictionary dictionaryWithCapacity:2];
	if (username) {
		[loginCredentials setObject:[NSString stringWithString:username] forKey:@"username"];
	}		
	[[NSUserDefaults standardUserDefaults] setObject:loginCredentials forKey:kBlioUserLoginCredentialsDefaultsKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}
-(void)saveUsername:(NSString*)username password:(NSString*)password sourceID:(BlioBookSourceID)sourceID {
	[self saveUsername:username];
	if (username) {
		if (password) {
			NSError * error = nil;
			[SFHFKeychainUtils storeUsername:username andPassword:password forServiceName:kBlioUserLoginCredentialsDefaultsKey updateExisting:YES error:&error];
			if (error) {
				NSLog(@"ERROR: could not store login credentials: %@",[error localizedDescription]);
			}
		}
		else {
			NSError * error = nil;
			[SFHFKeychainUtils deleteItemForUsername:username andServiceName:kBlioUserLoginCredentialsDefaultsKey error:&error];
			if (error) {
				NSLog(@"WARNING: error deleting password for username %@: %@",username,[error localizedDescription]);
			}
		}
	}
}
-(void)clearPasswordForSourceID:(BlioBookSourceID)sourceID {
	NSString * currentUsername = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:kBlioUserLoginCredentialsDefaultsKey] objectForKey:@"username"];
	if (currentUsername) {
		NSError * error = nil;
		[SFHFKeychainUtils deleteItemForUsername:currentUsername andServiceName:kBlioUserLoginCredentialsDefaultsKey error:&error];
		if (error) {
			NSLog(@"WARNING: error deleting password for username %@: %@",currentUsername,[error localizedDescription]);
		}
	}
}

-(void)saveRegistrationAccountID:(NSString*)accountID serviceID:(NSString*)serviceID {
	NSLog(@"saveRegistrationAccountID: %@, serviceID: %@",accountID,serviceID);
	NSMutableDictionary * usersDictionary = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:kBlioUsersDictionaryDefaultsKey] mutableCopy];
	if (!usersDictionary) {
		NSLog(@"WARNING: registration credentials attempted to be saved without existing usersDictionary!");
		return;
	}
	NSMutableDictionary * currentUserDictionary = [[usersDictionary objectForKey:[NSString stringWithFormat:@"%i",[[storeHelpers objectForKey:[NSNumber numberWithInt:BlioBookSourceOnlineStore]] userNum]]] mutableCopy];
	if (!currentUserDictionary) NSLog(@"WARNING: registration credentials attempted to be saved without existing currentUserDictionary!");
	else {
		NSMutableDictionary * registrationRecords = [NSMutableDictionary dictionaryWithCapacity:2];
		if (accountID) [registrationRecords setObject:[NSString stringWithString:accountID] forKey:kBlioAccountIDDefaultsKey];
		if (serviceID) [registrationRecords setObject:[NSString stringWithString:serviceID] forKey:kBlioServiceIDDefaultsKey];		
		[currentUserDictionary setObject:registrationRecords forKey:kBlioUserRegistrationRecordsDefaultsKey];
		[usersDictionary setObject:currentUserDictionary forKey:[NSString stringWithFormat:@"%i",[[storeHelpers objectForKey:[NSNumber numberWithInt:BlioBookSourceOnlineStore]] userNum]]];
		[[NSUserDefaults standardUserDefaults] setObject:usersDictionary forKey:kBlioUsersDictionaryDefaultsKey];	
		[currentUserDictionary release];
	}
	[usersDictionary release];
}
-(NSDictionary*)registrationRecords {
	NSDictionary * usersDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kBlioUsersDictionaryDefaultsKey];
	if (usersDictionary) {
		NSString * userNumString = [NSString stringWithFormat:@"%i",[[storeHelpers objectForKey:[NSNumber numberWithInt:BlioBookSourceOnlineStore]] userNum]];
		NSLog(@"getting registration records for user: %@",userNumString);
		NSDictionary * currentUserDictionary = [usersDictionary objectForKey:userNumString];
		if (currentUserDictionary) {
			return [currentUserDictionary objectForKey:kBlioUserRegistrationRecordsDefaultsKey];
		}
	}
	return nil;
}
-(void)loginWithUsername:(NSString*)user password:(NSString*)password sourceID:(BlioBookSourceID)sourceID {
	[self saveUsername:user];
	[[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] loginWithUsername:user password:password];
}
-(NSString*)loginHostnameForSourceID:(BlioBookSourceID)sourceID {
	return [[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] loginHostname];
}
-(void)storeHelper:(BlioStoreHelper*)storeHelper receivedLoginResult:(NSInteger)loginResult {
	NSLog(@"BlioStoreManager storeHelper: receivedLoginResult: %i",loginResult);
	initialLoginCheckFinished = YES;
	if (loginResult == BlioLoginResultInvalidPassword) {
		[[BlioStoreManager sharedInstance] clearPasswordForSourceID:storeHelper.sourceID];
	}	
	if (loginResult == BlioLoginResultInvalidPassword && isShowingLoginView == NO) {
		[[BlioStoreManager sharedInstance] showLoginViewForSourceID:storeHelper.sourceID];
	}
	else if (loginResult == BlioLoginResultError && isShowingLoginView == NO) {
		if (storeHelper.forceLoginDisplayUponFailure) {
			[[BlioStoreManager sharedInstance] showLoginViewForSourceID:storeHelper.sourceID];
		}	
		else {
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Server Error",@"\"Server Error\" alert message title") 
										 message:NSLocalizedStringWithDefaultValue(@"BACKGROUND_LOGIN_ERROR_SERVER_ERROR",nil,[NSBundle mainBundle],@"You cannot log in at the current time. Please try again later by going to your Archive or account settings.",@"Alert message when the login web service has failed.")
										delegate:nil 
							   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
							   otherButtonTitles:nil];		
		}			
	}
	else if (loginResult == BlioLoginResultConnectionError && isShowingLoginView == NO) {
		if (storeHelper.forceLoginDisplayUponFailure) {
			[[BlioStoreManager sharedInstance] showLoginViewForSourceID:storeHelper.sourceID];
		}	
		else {
			// silent logins currently do not show failure messages due to connection error
		}			
	}
	else if (isShowingLoginView == YES) {
		[loginViewController receivedLoginResult:loginResult];		
	}

	if (loginResult == BlioLoginResultSuccess) {
		// TODO: "DeviceRegistered" key should be refactored with multiple stores in mind.
//		NSLog(@"[storeHelper deviceRegistered]: %i",[storeHelper deviceRegistered]);
		if ([storeHelper deviceRegistered] == BlioDeviceRegisteredStatusUndefined) {
			
			[storeHelper setDeviceRegistered:BlioDeviceRegisteredStatusRegistered];
//			BlioDrmSessionManager* drmSessionManager = [[BlioDrmSessionManager alloc] initWithBookID:nil];
//			if ( ![drmSessionManager joinDomain:[[BlioStoreManager sharedInstance] tokenForSourceID:BlioBookSourceOnlineStore] domainName:@"novel"] )
//				TODO: alert
//			[drmSessionManager release];
			
			
			// ask end-user if he/she would like to register device
//			UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"This device is not registered...",@"\"This device is not registered...\" alert message title") 
//																 message:NSLocalizedStringWithDefaultValue(@"DEVICE_NOT_REGISTERED_MESSAGE",nil,[NSBundle mainBundle],@"This device is not yet registered for viewing paid content. Would you like to register this device now?",@"Alert message when login has succeeded but device is not registered for paid content.")
//																delegate:self 
//													   cancelButtonTitle:nil
//													   otherButtonTitles:@"Not Now", @"Register", nil];
//			[self.deviceRegistrationPromptAlertViews setObject:alertView forKey:[NSNumber numberWithInt:storeHelper.sourceID]];
//			[alertView show];
//			[alertView release];
		}		
		
		[[BlioStoreManager sharedInstance] loginFinishedForSourceID:storeHelper.sourceID];
	}
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSLog(@"buttonIndex: %i",buttonIndex);

	NSArray * keys = [self.deviceRegistrationPromptAlertViews allKeysForObject:alertView];
	if (keys && [keys count] > 0) {
		[self.deviceRegistrationPromptAlertViews removeObjectForKey:[keys objectAtIndex:0]];
		BlioStoreHelper * storeHelper = [self storeHelperForSourceID:[[keys objectAtIndex:0] intValue]];
		if (storeHelper ) {
			if ( buttonIndex == 1 ) {
				[storeHelper setDeviceRegistered:BlioDeviceRegisteredStatusRegistered];

//				BlioDrmSessionManager* drmSessionManager = [[BlioDrmSessionManager alloc] initWithBookID:nil];
//				if ( ![drmSessionManager joinDomain:[[BlioStoreManager sharedInstance] tokenForSourceID:BlioBookSourceOnlineStore] domainName:@"novel"] )
//					TODO: show alert
//				[drmSessionManager release];
			}
			else if (buttonIndex == 0) {
				[storeHelper setDeviceRegistered:BlioDeviceRegisteredStatusUnregistered];
			}
		}
	}
}

-(BOOL)isLoggedInForSourceID:(BlioBookSourceID)sourceID {
	if ([storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]]) return [[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] isLoggedIn];
	else return NO;
}
-(NSString*)usernameForSourceID:(BlioBookSourceID)sourceID {
	if ([storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]]) return [[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] username];
	else return nil;
}
-(void)retrieveBooksForSourceID:(BlioBookSourceID)sourceID {
	if ([storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]]) [[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] retrieveBooks];
	else NSLog(@"WARNING: Cannot retrieve books, there is no store helper for sourceID: %i",sourceID);
}
- (NSString*)tokenForSourceID:(BlioBookSourceID)sourceID {
//	return @"0cac1444-f4a7-4d47-96c8-6a926bc10a00";
	if ([storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] && [[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] hasValidToken]) return [[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] token];
	return nil;
}
- (void)logoutForSourceID:(BlioBookSourceID)sourceID {
	[[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] logout];
}
-(NSString*)savedLoginUsername {
	NSDictionary * credentials = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kBlioUserLoginCredentialsDefaultsKey];
	if (credentials) {
		return [credentials objectForKey:@"username"];
	}
	return nil;
}
-(BOOL)hasLoginCredentials {
	NSDictionary * credentials = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kBlioUserLoginCredentialsDefaultsKey];
	if (credentials && [credentials objectForKey:@"username"]) {
		NSError * error = nil;
		NSString * password = [SFHFKeychainUtils getPasswordForUsername:[credentials objectForKey:@"username"] andServiceName:kBlioUserLoginCredentialsDefaultsKey error:&error];
		if (error) {
			NSLog(@"ERROR: tried to obtain password in hasLoginCredentials: %@",[error localizedDescription]);
			return NO;
		}
		else if (password) return YES;
	}
	return NO;
}
-(NSURL*)URLForBookWithSourceID:(BlioBookSourceID)sourceID sourceSpecificID:(NSString*)sourceSpecificID {
	if ([storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]]) return [[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] URLForBookWithID:sourceSpecificID];
	return nil;	
}
-(BlioDeviceRegisteredStatus)deviceRegisteredForSourceID:(BlioBookSourceID)sourceID {
	return [[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] deviceRegistered];
}
-(BOOL)setDeviceRegisteredSettingOnly:(BlioDeviceRegisteredStatus)status forSourceID:(BlioBookSourceID)sourceID {
	return [[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] setDeviceRegisteredSettingOnly:status];
}
-(BOOL)setDeviceRegistered:(BlioDeviceRegisteredStatus)status forSourceID:(BlioBookSourceID)sourceID {
	return [[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] setDeviceRegistered:status];
}

@end
