//
//  BlioStoreManager.m
//  BlioApp
//
//  Created by Don Shin on 5/7/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import "BlioStoreManager.h"
#import "BlioOnlineStoreHelper.h"
#import "BlioAlertManager.h"
#import "BlioDrmSessionManager.h"
#import "BlioAppSettingsConstants.h"
#import "BlioWelcomeViewController.h"
#import "BlioLoginService.h"
#import "BlioIdentityProvidersViewController.h"

@implementation BlioStoreManager

@synthesize storeHelpers, isShowingLoginView, rootViewController, welcomeViewController, deviceRegistrationPromptAlertViews,currentStoreHelper,initialLoginCheckFinished;
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
	self.welcomeViewController = nil;
	[super dealloc];
}

-(void)addStoreHelper:(BlioStoreHelper*)helper {
	helper.delegate = self;
	[storeHelpers setObject:helper forKey:[NSNumber numberWithInt:helper.sourceID]];
	if (!currentStoreHelper) self.currentStoreHelper = helper;
}

-(void)buyBookWithSourceSpecificID:(NSString*)sourceSpecificID {
	[self.currentStoreHelper buyBookWithSourceSpecificID:sourceSpecificID];
}

-(void)requestLoginForSourceID:(BlioBookSourceID)sourceID {
	[self requestLoginForSourceID:sourceID forceLoginDisplayUponFailure:NO];
}

-(void)requestLoginForSourceID:(BlioBookSourceID)sourceID forceLoginDisplayUponFailure:(BOOL)forceLoginDisplay {
    if (sourceID != BlioBookSourceOnlineStore)
        return;
    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    [[BlioLoginService sharedInstance] getIdentityProviders:session];
	
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
	self.welcomeViewController = [[[BlioWelcomeViewController alloc] initWithSourceID:sourceID] autorelease];
	UINavigationController * modalWelcomeNavigationController = [[[UINavigationController alloc] initWithRootViewController:welcomeViewController] autorelease];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		modalWelcomeNavigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		modalWelcomeNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	[((UINavigationController*)rootViewController).visibleViewController presentModalViewController:modalWelcomeNavigationController animated:YES];
	isShowingLoginView = YES;	
}

-(void)dismissLoginView {
    [((UINavigationController*)rootViewController).visibleViewController dismissModalViewControllerAnimated:NO];
}


-(void)loginFinishedForSourceID:(BlioBookSourceID)sourceID {
    [self dismissLoginView];
	isShowingLoginView = NO;
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
	[userInfo setValue:[NSNumber numberWithInt:sourceID] forKey:@"sourceID"];  // TODO? other userInfo from BlioAccountService
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioLoginFinished object:self userInfo:userInfo];

}

-(void)retrieveToken {
    BlioStoreHelper* helper = [[BlioStoreManager sharedInstance] storeHelperForSourceID:BlioBookSourceOnlineStore];
    NSDictionary* userToken = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kBlioUserTokenDefaultsKey];
    helper.token = [userToken valueForKey:@"token"];
    helper.timeout = [userToken objectForKey:@"timeout"];
}

-(void)saveToken {
    BlioStoreHelper* helper = [[BlioStoreManager sharedInstance] storeHelperForSourceID:BlioBookSourceOnlineStore];
	NSMutableDictionary * tokenDict = [NSMutableDictionary dictionaryWithCapacity:2];
	[tokenDict setValue:helper.token forKey:@"token"];
	[tokenDict setObject:helper.timeout forKey:@"timeout"];
	[[NSUserDefaults standardUserDefaults] setObject:tokenDict forKey:kBlioUserTokenDefaultsKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)saveRegistrationAccountID:(NSString*)accountID serviceID:(NSString*)serviceID {
//	NSLog(@"saveRegistrationAccountID: %@, serviceID: %@",accountID,serviceID);
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

-(BOOL)isLoggedInForSourceID:(BlioBookSourceID)sourceID {
	if ([storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]])
        return [[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] isLoggedIn];
	else
        return NO;
}

-(NSString*)usernameForSourceID:(BlioBookSourceID)sourceID {
	if ([storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]])
        return [[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] username];
	else
        return nil;
}

-(void)retrieveBooksForSourceID:(BlioBookSourceID)sourceID {
	if ([storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]]) [[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] retrieveBooks];
	else NSLog(@"WARNING: Cannot retrieve books, there is no store helper for sourceID: %i",sourceID);
}

- (NSString*)tokenForSourceID:(BlioBookSourceID)sourceID {
//	return @"0cac1444-f4a7-4d47-96c8-6a926bc10a00";
	if ([storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] && [[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] hasValidToken])
        return [[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] token];
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

-(BOOL)setDeviceRegisteredSettingOnly:(BlioDeviceRegisteredStatus)status forSourceID:(BlioBookSourceID)sourceID {
	return [[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] setDeviceRegisteredSettingOnly:status];
}

-(BOOL)setDeviceRegistered:(BlioDeviceRegisteredStatus)status forSourceID:(BlioBookSourceID)sourceID {
	return [[storeHelpers objectForKey:[NSNumber numberWithInt:sourceID]] setDeviceRegistered:status];
}

#pragma mark -
#pragma mark NSURLSessionDataDelegate methods

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error || !providersData ) {
        [self loginFinishedForSourceID:BlioBookSourceOnlineStore];
        [BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Identity Providers Unavailable",@"\"Identity Providers Unavailable\" alert message title")
                                     message:[NSString stringWithFormat:@"Identity providers could not be retrieved because of an error: %@.  Please try again later.",[error description]]
                                    delegate:self
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil];
        return;
    }
    NSError* err;
    id providers = [NSJSONSerialization
                                 JSONObjectWithData:providersData
                                 options:kNilOptions
                    error:&err];
    if (!providers || ![providers isKindOfClass:[NSArray class]]) {
        [self loginFinishedForSourceID:BlioBookSourceOnlineStore];
        [BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Identity Providers Unavailable",@"\"Identity Providers Unavailable\" alert message title")
                                     message:[NSString stringWithFormat:@"Identity providers could not be retrieved."]
                                    delegate:self
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil];
    }
    else {
        // Get the thumbnail image for each provider.
        // Don't know why "__block" isn't needed here; on the contrary it makes the variable inaccessible in the block.
        NSMutableDictionary* providersInfo = [NSMutableDictionary dictionaryWithCapacity:[providers count]];
        numImages = 0;
        for(int i=0;i<[providers count];i++)
        {
            NSDictionary* provider = [providers objectAtIndex:i];
            NSString* name = [provider objectForKey:@"Name"];
            NSMutableDictionary* providerDict = [NSMutableDictionary dictionaryWithCapacity:3];
            [providerDict setValue:[provider valueForKey:@"LogoutUrl"] forKey:@"LogoutURL"];
            [providerDict setValue:[provider valueForKey:@"LoginUrl"] forKey:@"LoginURL"];
            [providersInfo setValue:providerDict forKey:name];
            NSString* imageURL = [[providers objectAtIndex:i] objectForKey:@"ImageUrl"];
            NSMutableURLRequest *imageRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:imageURL]];
            NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
                __block NSURLSessionDataTask* task = [session dataTaskWithRequest:imageRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                //NSLog(@"Got response %@ with error %@.\n", response, error);
                //NSLog(@"In handler for provider %@",task.taskDescription);
                if (!error) {
                    UIImage *image = [UIImage imageWithData:data scale:2.0];
                    NSDictionary* dict = [providersInfo valueForKey:task.taskDescription];
                    [dict setValue:image forKey:@"Image"];
                    @synchronized(self) {
                        [providersInfo setValue:dict forKey:task.taskDescription];
                    }
                }
                else
                    NSLog(@"Image retrieval failed for %@",task.taskDescription);
                if (++numImages == [providers count]) {
                    BlioIdentityProvidersViewController* providersController = [[BlioIdentityProvidersViewController alloc] initWithProviders:providersInfo];
                    UINavigationController * modalLoginNavigationController = [[[UINavigationController alloc] initWithRootViewController:providersController] autorelease];
                    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                        modalLoginNavigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                        modalLoginNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
                    }
                    [((UINavigationController*)rootViewController).visibleViewController presentModalViewController:modalLoginNavigationController animated:YES];
                    isShowingLoginView = YES;
                    [providersController release];
                }
            }];
            [imageRequest release];
            task.taskDescription = name;
            [task resume];
        }
        
     }
    providersData = nil;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if (data) {
        if (!providersData)
            providersData = [[NSMutableData alloc] initWithCapacity:16];
        [providersData appendData:data];
    }
}

@end
