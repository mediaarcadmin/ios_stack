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

BlioStoreManager * sharedLoginManager = nil;

@implementation BlioStoreManager

@synthesize storeHelpers, isShowingLoginView, rootViewController,loginViewController;
@synthesize processingDelegate = _processingDelegate;

+(BlioStoreManager*)sharedInstance
{
	if (sharedLoginManager == nil) {
		sharedLoginManager = [[BlioStoreManager alloc] init];
	}
	
	return sharedLoginManager;
}
- (id) init {
	if((self = [super init])) {
		self.storeHelpers = [NSMutableDictionary dictionaryWithCapacity:1];
		[self setStoreHelper:[[[BlioOnlineStoreHelper alloc] init] autorelease]];
	}
	return self;
}
-(void)setStoreHelper:(BlioStoreHelper*)helper {
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
-(NSString*)storeTitleForSourceID:(BlioBookSourceID)sourceID {
	for (id key in self.storeHelpers) {
		if ([key intValue] == sourceID) return ((BlioStoreHelper*)[self.storeHelpers objectForKey:key]).storeTitle; 
	}
	return nil;
}
-(void)showLoginViewForSourceID:(BlioBookSourceID)sourceID {
	self.loginViewController = [[[BlioLoginViewController alloc] initWithSourceID:sourceID] autorelease];
	[((UINavigationController*)rootViewController).visibleViewController presentModalViewController:[[[UINavigationController alloc] initWithRootViewController:loginViewController] autorelease] animated:YES];
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
	if (loginResult != BlioLoginResultSuccess && isShowingLoginView == NO) {
		[[BlioStoreManager sharedInstance] showLoginViewForSourceID:storeHelper.sourceID];
	}
	else if (isShowingLoginView == YES) {
		[loginViewController receivedLoginResult:loginResult];	
	}

	if (loginResult == BlioLoginResultSuccess) [[BlioStoreManager sharedInstance] loginFinishedForSourceID:storeHelper.sourceID];
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
	if ([storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]]) return [[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] token];
	return nil;
}
- (void)logoutForSourceID:(BlioBookSourceID)sourceID {
	[[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] logout];
}
-(NSURL*)URLForBookWithSourceID:(BlioBookSourceID)sourceID sourceSpecificID:(NSString*)sourceSpecificID {
	if ([storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]]) return [[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] URLForBookWithID:sourceSpecificID];
	return nil;	
}
-(void) dealloc {
	self.storeHelpers = nil;
	self.rootViewController = nil;
	self.loginViewController = nil;
	[super dealloc];
}
@end
