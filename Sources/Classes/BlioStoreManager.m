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

@implementation BlioStoreManager

@synthesize storeHelpers, isShowingLoginView, rootViewController,loginViewController,deviceRegistrationPromptAlertViews;
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
}
-(void)requestLoginForSourceID:(BlioBookSourceID)sourceID {
	// first check to see if login info is in NSUserDefaults
	
	NSMutableDictionary * loginCredentials = [[NSUserDefaults standardUserDefaults] objectForKey:[self storeTitleForSourceID:sourceID]];
	if (loginCredentials && [loginCredentials objectForKey:@"username"] && [loginCredentials objectForKey:@"password"]) {
		[[BlioStoreManager sharedInstance] loginWithUsername:[loginCredentials objectForKey:@"username"] password:[loginCredentials objectForKey:@"password"] sourceID:sourceID];
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
-(void)showLoginViewForSourceID:(BlioBookSourceID)sourceID {
	self.loginViewController = [[[BlioLoginViewController alloc] initWithSourceID:sourceID] autorelease];
	
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
-(void)loginFinishedForSourceID:(BlioBookSourceID)sourceID {
	isShowingLoginView = NO;
	self.loginViewController = nil;
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
	[userInfo setValue:[NSNumber numberWithInt:sourceID] forKey:@"sourceID"];
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioLoginFinished object:self userInfo:userInfo];

}
-(void)loginWithUsername:(NSString*)user password:(NSString*)password sourceID:(BlioBookSourceID)sourceID {	
	[[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] loginWithUsername:user password:password];
}
-(void)storeHelper:(BlioStoreHelper*)storeHelper receivedLoginResult:(NSInteger)loginResult {
	NSLog(@"BlioStoreManager storeHelper: receivedLoginResult: %i",loginResult);
	if (loginResult != BlioLoginResultSuccess && isShowingLoginView == NO) {
		[[BlioStoreManager sharedInstance] showLoginViewForSourceID:storeHelper.sourceID];
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
//				[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"An Error Has Occurred...",@"\"An Error Has Occurred...\" alert message title") 
//											 message:NSLocalizedStringWithDefaultValue(@"REGISTRATION_FAILED",nil,[NSBundle mainBundle],@"Unable to register device. Please try again later.",@"Alert message shown when device registration fails.")
//											delegate:nil 
//								   cancelButtonTitle:nil
//								   otherButtonTitles:@"OK", nil];
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
//					[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"An Error Has Occurred...",@"\"An Error Has Occurred...\" alert message title") 
//												 message:NSLocalizedStringWithDefaultValue(@"REGISTRATION_FAILED",nil,[NSBundle mainBundle],@"Unable to register device. Please try again later.",@"Alert message shown when device registration fails.")
//													delegate:nil 
//												cancelButtonTitle:nil
//												otherButtonTitles:@"OK", nil];
//				[drmSessionManager release];
			}
			else if (buttonIndex == 0)
				[[NSUserDefaults standardUserDefaults] setInteger:BlioDeviceRegisteredStatusUnregistered forKey:kBlioDeviceRegisteredDefaultsKey];
		}
	}
}

-(BOOL)isLoggedInForSourceID:(BlioBookSourceID)sourceID {
	if ([storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]]) return [[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] isLoggedIn];
	else return NO;
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
-(NSURL*)URLForBookWithSourceID:(BlioBookSourceID)sourceID sourceSpecificID:(NSString*)sourceSpecificID {
	if ([storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]]) return [[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] URLForBookWithID:sourceSpecificID];
	return nil;	
}
-(BlioDeviceRegisteredStatus)deviceRegisteredForSourceID:(BlioBookSourceID)sourceID {
	return [[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] deviceRegistered];
}
-(BOOL)setDeviceRegistered:(BlioDeviceRegisteredStatus)status forSourceID:(BlioBookSourceID)sourceID {
	return [[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] setDeviceRegistered:status];
}

@end
