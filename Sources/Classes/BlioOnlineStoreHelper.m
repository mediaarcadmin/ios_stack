//
//  BlioOnlineStoreHelper.m
//  BlioApp
//
//  Created by Arnold Chien and Don Shin on 4/5/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import "BlioOnlineStoreHelper.h"
#import "BlioBookVault.h"
#import "BlioStoreManager.h"
#import "BlioAlertManager.h"
#import "BlioAppSettingsConstants.h"
#import	"Reachability.h"
#import "BlioDrmSessionManager.h"

// N.B. - For other stores besides the default, BlioOnlineStoreHelper should be subclassed and the init overridden.
//#define KNFB_STORE 12151
//#define HP_STORE 12308
//#define TOSHIBA_STORE 12309
//#define DELL_STORE 12327
//#define BLIO_IPHONE_VERSION 12555

@interface BlioOnlineStoreHelper (PRIVATE)
- (void) bookVaultSoapOperation:(BookVaultSoapOperation *)operation completedWithResponse:(BookVaultSoapResponse *)response;
- (void) contentCafeSoapOperation:(ContentCafeSoapOperation *)operation completedWithResponse:(ContentCafeSoapResponse *)response;
- (void)getContentMetaDataFromISBN:(NSString*)isbn;
-(void)assessRetrieveBooksProgress;
-(void)retrieveTokenWithUsername:(NSString*)user password:(NSString*)password;
@end

@implementation BlioOnlineStoreHelperBookVaultDelegate
@synthesize delegate;
- (void) operation:(BookVaultSoapOperation *)operation completedWithResponse:(BookVaultSoapResponse *)response {
	[delegate bookVaultSoapOperation:operation completedWithResponse:response];
}
@end


@implementation BlioOnlineStoreHelperContentCafeDelegate
@synthesize delegate;
- (void) operation:(ContentCafeSoapOperation *)operation completedWithResponse:(ContentCafeSoapResponse *)response {
	[delegate contentCafeSoapOperation:operation completedWithResponse:response];
}
@end

@implementation BlioOnlineStoreHelper

- (id) init {
	if((self = [super init])) {
		self.sourceID = BlioBookSourceOnlineStore;
		self.storeTitle = @"Blio Online Store";
		self.siteID = 12555;
		self.siteKey = @"B870B960A5B4CB53363BB10855FDC3512658E69E";
		bookVaultDelegate = [[BlioOnlineStoreHelperBookVaultDelegate alloc] init];
		bookVaultDelegate.delegate = self;
		contentCafeDelegate = [[BlioOnlineStoreHelperContentCafeDelegate alloc] init];
		contentCafeDelegate.delegate = self;
		downloadNewBooks = YES;
	}
	return self;
}
-(void) dealloc {
	[bookVaultDelegate release];
	[contentCafeDelegate release];
	[super dealloc];
}
- (void)loginWithUsername:(NSString*)user password:(NSString*)password {
	currentUsername = [user retain];
	currentPassword = [password retain];
	if (!self.userNum > 0) {
		DigitalLockerRequest * request = [[DigitalLockerRequest alloc] init];
		request.Service = DigitalLockerServiceRegistration;
		request.Method = DigitalLockerMethodLogin;
		NSMutableDictionary * inputData = [NSMutableDictionary dictionaryWithCapacity:2];
		[inputData setObject:user forKey:DigitalLockerInputDataEmailKey];
		[inputData setObject:password forKey:DigitalLockerInputDataPasswordKey];
		request.InputData = inputData;
		DigitalLockerConnection * connection = [[DigitalLockerConnection alloc] initWithDigitalLockerRequest:request siteNum:self.siteID siteKey:self.siteKey delegate:self];
		[connection start];
		[request release];		
	}
	else [self retrieveTokenWithUsername:user password:password];
}
-(void)retrieveTokenWithUsername:(NSString*)user password:(NSString*)password {
	BookVaultSoap *vaultBinding = [[BookVault BookVaultSoap] retain];
	//vaultBinding.logXMLInOut = YES;
	BookVault_Login *loginRequest = [[BookVault_Login new] autorelease];
	loginRequest.username = user;	
	loginRequest.password = password; 
	loginRequest.siteId =  [NSNumber numberWithInt:self.siteID];
	[vaultBinding LoginAsyncUsingParameters:loginRequest delegate:bookVaultDelegate];
	[vaultBinding release];
}
- (void) bookVaultSoapOperation:(BookVaultSoapOperation *)operation completedWithResponse:(BookVaultSoapResponse *)response {
	if (!response.responseType) {
		NSLog(@"ERROR: response has no response type!");
		return;
	}
	if ([response.responseType isEqualToString:BlioBookVaultResponseTypeLogin]) {
		
		NSArray *responseBodyParts = response.bodyParts;
		for(id bodyPart in responseBodyParts) {
//			NSLog(@"bodyPart: %@",bodyPart);
		}
		for(id bodyPart in responseBodyParts) {
			if ([bodyPart isKindOfClass:[SOAPFault class]]) {
				NSString* err = ((SOAPFault *)bodyPart).simpleFaultString;
				NSLog(@"SOAP error for login: %@",err);
				[delegate storeHelper:self receivedLoginResult:BlioLoginResultError];
				return;
			}
			NSLog(@"[[bodyPart LoginResult].ReturnCode intValue]: %i",[[bodyPart LoginResult].ReturnCode intValue]);
			if ( [[bodyPart LoginResult].ReturnCode intValue] == 200 ) { 
				self.token = [bodyPart LoginResult].Token;
				NSLog(@"set token: %@",self.token);
				self.timeout = [[NSDate date] addTimeInterval:(NSTimeInterval)[[bodyPart LoginResult].Timeout floatValue]];
				NSLog(@"timeout: %@",self.timeout);
//				if ([self deviceRegistered]) {
//					NSLog(@"rejoining domain...");
//					BlioDrmSessionManager* drmSessionManager = [[BlioDrmSessionManager alloc] initWithBookID:nil];
//					if ( ![drmSessionManager joinDomain:self.token domainName:@"novel"] ) {
//						NSLog(@"ERROR: newly logged in user could not rejoin registration domain!");
//					}
//					[drmSessionManager release];
//				}
				[delegate storeHelper:self receivedLoginResult:BlioLoginResultSuccess];
				return;
			}
			else if ( [[bodyPart LoginResult].ReturnCode intValue] == 203 ) {
				NSLog(@"Invalid password");
				
				[delegate storeHelper:self receivedLoginResult:BlioLoginResultInvalidPassword];
				return;
			}
			else {
				NSLog(@"Login error: %@",[bodyPart LoginResult].Message);
				[delegate storeHelper:self receivedLoginResult:BlioLoginResultError];
				return;
			}
		}
	}
	else if ([response.responseType isEqualToString:BlioBookVaultResponseTypeVaultContentsWithToken]) {
		NSArray *responseBodyParts = response.bodyParts;
		for(id bodyPart in responseBodyParts) {
			if ([bodyPart isKindOfClass:[SOAPFault class]]) {
				NSString* err = ((SOAPFault *)bodyPart).simpleFaultString;
				NSLog(@"SOAP error for VaultContents: %@",err);
				// TODO: Message
				return;
			}
			else if ( [[bodyPart VaultContentsWithTokenResult].ReturnCode intValue] == 300 ) { 
				if (_isbns) [_isbns release]; // release old set of ISBNs
				_isbns = [[bodyPart VaultContentsWithTokenResult].Contents.string retain];
			}
			else {
				NSLog(@"VaultContents error: %@",[bodyPart VaultContentsWithTokenResult].Message);
				// TODO: Message
				return;
			}
		}
		// add new book entries to PersistentStore as appropriate
		NSLog(@"ISBN count: %i",[_isbns count]);
		newISBNs = 0;
		responseCount = 0;
		successfulResponseCount = 0;
		
		for (NSString * isbn in _isbns) {
			
			// check to see if BlioBook record is already in the persistent store
			
			if ([[BlioStoreManager sharedInstance].processingDelegate bookWithSourceID:self.sourceID sourceSpecificID:isbn] == nil) {
				newISBNs++;
				[self getContentMetaDataFromISBN:isbn];
			}
			else {
				NSLog(@"We already have ISBN: %@ in our persistent store, no need to get meta data for this item.",isbn);
			}
		}
		if (newISBNs == 0) [self assessRetrieveBooksProgress];
	}
}
- (void) contentCafeSoapOperation:(ContentCafeSoapOperation *)operation completedWithResponse:(ContentCafeSoapResponse *)response {
	responseCount++;
	NSArray *responseBodyParts = response.bodyParts;
	if (responseBodyParts == nil) {
		NSLog(@"ERROR: responseBodyParts is nil. response: %@",response);
	}
	ContentCafe_RequestItems* requestItems;
	for(id bodyPart in responseBodyParts) {
		if (response.error) {
			// likely a network error
			NSLog(@"ERROR: %@",[response.error localizedDescription]);
		}
		else if ([bodyPart isKindOfClass:[SOAPFault class]]) {
			NSString* err = ((SOAPFault *)bodyPart).simpleFaultString;
			NSLog(@"SOAP error for ContentCafe_XmlClassResponse: %s",err);
			// TODO: Message
		}
		else if ( (requestItems = [[bodyPart ContentCafe] RequestItems]) ) { 
			ContentCafe_RequestItem* requestItem = (ContentCafe_RequestItem*)[[requestItems RequestItem] objectAtIndex:0];
			ContentCafe_ProductItem* productItem =(ContentCafe_ProductItem*)[[[requestItem ProductItems] ProductItem] objectAtIndex:0];
			if (productItem) {
				successfulResponseCount++;
				NSString* title = [[productItem Title] Value];
				NSString* author = [productItem Author];
				NSString* coverURL = [NSString stringWithFormat:@"http://images.btol.com/cc2images/Image.aspx?SystemID=knfb&IdentifierID=I&IdentifierValue=%@&Source=BT&Category=FC&Sequence=1&Size=L&NotFound=S",[productItem ISBN]];
				NSLog(@"Title: %@", title);
				NSLog(@"Author: %@", author);
				NSLog(@"Cover: %@", coverURL);
//				NSLog(@"URL: %@",[[self URLForBookWithID:[productItem ISBN]] absoluteString]);
				NSMutableArray * authors = [NSMutableArray array];
				if (author) {
					NSArray * preTrimmedAuthors = [author componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@";"]];
					for (NSString * preTrimmedAuthor in preTrimmedAuthors) {
						[authors addObject:[preTrimmedAuthor stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
					}
				}
				if ( [[NSUserDefaults standardUserDefaults] integerForKey:kBlioDownloadNewBooksDefaultsKey] >= 0) {
					downloadNewBooks = YES;
				}
				else downloadNewBooks = NO;
				
				[[BlioStoreManager sharedInstance].processingDelegate enqueueBookWithTitle:title 
																				   authors:authors   
																				 coverPath:coverURL
																				  ePubPath:nil 
																				   pdfPath:nil 
																				   xpsPath:nil
																			  textFlowPath:nil 
																			 audiobookPath:nil 
																				  sourceID:BlioBookSourceOnlineStore 
																		  sourceSpecificID:[productItem ISBN]
																		   placeholderOnly:(!downloadNewBooks)
				 ];
			}
			else {
				NSLog(@"ERROR: productItem is nil!");
			}			
		}
		else {
			NSLog(@"ContentCafe_XmlClassResponse error.");
		}
	}
	[self assessRetrieveBooksProgress];
}
-(void)assessRetrieveBooksProgress {
	if (responseCount == [_isbns count] || newISBNs == 0) { 
		NSString * ISBNMetadataResponseAlertText = nil;
		if (successfulResponseCount == 0 && newISBNs > 0) {
			// we didn't get any successful responses, though we have a need for ISBN metadata.
			ISBNMetadataResponseAlertText = NSLocalizedStringWithDefaultValue(@"ISBN_METADATA_ALL_ATTEMPTS_FAILED",nil,[NSBundle mainBundle],@"The app was not able to retrieve your latest purchases at this time due to a server error. Please try logging in again later.",@"Alert message when all attempts to access the ISBN meta-data web service fail.");
		}
		else if (successfulResponseCount < newISBNs) {
			// we got some successful responses, though not all for the new ISBNs.
			ISBNMetadataResponseAlertText = NSLocalizedStringWithDefaultValue(@"ISBN_METADATA_SOME_ATTEMPTS_FAILED",nil,[NSBundle mainBundle],@"The app was able to retrieve some but not all of your latest purchases at this time due to a server error. Please try logging in again later.",@"Alert message when some but not all attempts to access the ISBN meta-data web service fail.");
		}
		if (ISBNMetadataResponseAlertText != nil) {
			// show alert box
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"We're Sorry...",@"\"We're Sorry...\" alert message title")
										 message:ISBNMetadataResponseAlertText
										delegate:nil 
							   cancelButtonTitle:@"OK"
							   otherButtonTitles: nil];
		}
		NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
		[userInfo setObject:[NSNumber numberWithInt:self.sourceID] forKey:@"sourceID"];
		isRetrievingBooks = NO;
		[[NSNotificationCenter defaultCenter] postNotificationName:BlioStoreRetrieveBooksFinished object:self userInfo:userInfo];		 
	}
}
-(BOOL)hasValidToken {
	if (self.token == nil) return NO;
	if ([self.timeout compare:[NSDate date]] == NSOrderedDescending) return YES;
	return NO;
}
-(BlioDeviceRegisteredStatus)deviceRegistered {
	NSMutableDictionary * usersDictionary = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:kBlioUsersDictionaryDefaultsKey] mutableCopy];
	if (usersDictionary) {
		NSMutableDictionary * currentUserDictionary = [[usersDictionary objectForKey:[NSString stringWithFormat:@"%i",[self userNum]]] mutableCopy];
		if (currentUserDictionary && [currentUserDictionary objectForKey:kBlioDeviceRegisteredDefaultsKey]) {
			return [[currentUserDictionary objectForKey:kBlioDeviceRegisteredDefaultsKey] intValue];
		}
	}
	return 0;
}
-(BOOL) setDeviceRegisteredSettingOnly:(BlioDeviceRegisteredStatus)targetStatus {
	NSMutableDictionary * usersDictionary = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:kBlioUsersDictionaryDefaultsKey] mutableCopy];
	if (!usersDictionary) usersDictionary = [NSMutableDictionary dictionary];
	NSMutableDictionary * currentUserDictionary = [[usersDictionary objectForKey:[NSString stringWithFormat:@"%i",[self userNum]]] mutableCopy];
	if (!currentUserDictionary) currentUserDictionary = [NSMutableDictionary dictionary];				
	[currentUserDictionary setObject:[NSNumber numberWithInt:targetStatus] forKey:kBlioDeviceRegisteredDefaultsKey];
	[usersDictionary setObject:currentUserDictionary forKey:[NSString stringWithFormat:@"%i",[self userNum]]];
	[[NSUserDefaults standardUserDefaults] setObject:usersDictionary forKey:kBlioUsersDictionaryDefaultsKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
	return YES;
}
-(BOOL) setDeviceRegistered:(BlioDeviceRegisteredStatus)targetStatus {
	if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
		NSString * internetMessage = NSLocalizedStringWithDefaultValue(@"INTERNET_REQUIRED_DEREGISTRATION",nil,[NSBundle mainBundle],@"An Internet connection was not found; Internet access is required to deregister this device.",@"Alert message when the user tries to deregister the device without an Internet connection.");
		if (targetStatus == BlioDeviceRegisteredStatusRegistered) internetMessage = NSLocalizedStringWithDefaultValue(@"INTERNET_REQUIRED_REGISTRATION",nil,[NSBundle mainBundle],@"An Internet connection was not found; Internet access is required to register this device.",@"Alert message when the user tries to register the device without an Internet connection.");
		
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"We're Sorry...",@"\"We're Sorry...\" alert message title")
									 message:internetMessage
									delegate:nil 
						   cancelButtonTitle:@"OK"
						   otherButtonTitles: nil];		
		return NO;
	}
	if (![self hasValidToken]) {
		NSString * loginMessage = NSLocalizedStringWithDefaultValue(@"LOGIN_REQUIRED_DEREGISTRATION",nil,[NSBundle mainBundle],@"You must be logged in to deregister this device.",@"Alert message when the user tries to deregister the device without being logged in.");
		if (targetStatus == BlioDeviceRegisteredStatusRegistered) loginMessage = NSLocalizedStringWithDefaultValue(@"INTERNET_REQUIRED_REGISTRATION",nil,[NSBundle mainBundle],@"You must be logged in to register this device.",@"Alert message when the user tries to register the device without being logged in.");
		
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"We're Sorry...",@"\"We're Sorry...\" alert message title")
									 message:loginMessage
									delegate:nil 
						   cancelButtonTitle:@"OK"
						   otherButtonTitles: nil];		
		return NO;
	}
	BlioDrmSessionManager* drmSessionManager = [[BlioDrmSessionManager alloc] initWithBookID:nil];
	if ( targetStatus == BlioDeviceRegisteredStatusRegistered ) {
		if ( ![drmSessionManager joinDomain:self.token domainName:@"novel"] ) {
			[drmSessionManager release];
			return NO;
		} 
	}
	else {
		if ( ![drmSessionManager leaveDomain:self.token] ) {
			[drmSessionManager release];
			return NO;
		}
		else { 
			// de-registration succeeded, delete current user's books
			[[BlioStoreManager sharedInstance].processingDelegate deletePaidBooksForUserNum:userNum siteNum:siteID];
		}
	}
	[drmSessionManager release];
	[self setDeviceRegisteredSettingOnly:targetStatus];
	return YES;
}
- (void)logout {
	self.token = nil;
	self.userNum = 0;
	if (currentUsername) {
		[currentUsername release];
		currentUsername = nil;
	}
	if (currentPassword) {
		[currentPassword release];
		currentPassword = nil;
	}
	self.timeout = [NSDate distantPast];
	[[BlioStoreManager sharedInstance] saveUsername:nil password:nil sourceID:sourceID];
}
-(void)retrieveBooks {
	if (![BlioStoreManager sharedInstance].processingDelegate) {
		NSLog(@"ERROR: no processingManager set for BlioOnlineStoreHelper! Aborting retrieveBooks...");
		return;
	}
	if (![self hasValidToken]) {
		NSLog(@"ERROR: Store helper does not have a valid token! Aborting retrieveBooks...");
		return;
	}
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
	[userInfo setObject:[NSNumber numberWithInt:self.sourceID] forKey:@"sourceID"];
	isRetrievingBooks = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioStoreRetrieveBooksStarted object:self userInfo:userInfo];

	BookVaultSoap *vaultBinding = [[BookVault BookVaultSoap] retain];
	//vaultBinding.logXMLInOut = YES;
	BookVault_VaultContentsWithToken* vaultContentsRequest = [[BookVault_VaultContentsWithToken new] autorelease];
	vaultContentsRequest.token = [[BlioStoreManager sharedInstance] tokenForSourceID:BlioBookSourceOnlineStore]; 
	[vaultBinding VaultContentsWithTokenAsyncUsingParameters:vaultContentsRequest delegate:bookVaultDelegate];
	[vaultBinding release];
}
-(NSURL*)URLForBookWithID:(NSString*)isbn {
	BookVaultSoap *vaultBinding = [[BookVault BookVaultSoap] retain];
	vaultBinding.logXMLInOut = YES;
	BookVault_RequestDownloadWithToken* downloadRequest = [[BookVault_RequestDownloadWithToken new] autorelease];
	downloadRequest.token = [[BlioStoreManager sharedInstance] tokenForSourceID:BlioBookSourceOnlineStore]; 
	downloadRequest.isbn = isbn;
	BookVaultSoapResponse* response = [vaultBinding RequestDownloadWithTokenUsingParameters:downloadRequest];
	[vaultBinding release];
	NSArray *responseBodyParts = response.bodyParts;
	for(id bodyPart in responseBodyParts) {
		if ([bodyPart isKindOfClass:[SOAPFault class]]) {
			NSString* err = ((SOAPFault *)bodyPart).simpleFaultString;
			NSLog(@"SOAP error for VaultContents: %@",err);
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"An Error Has Occurred...",@"\"An Error Has Occurred...\" alert message title") 
										 message:NSLocalizedStringWithDefaultValue(@"DOWNLOADURL_SERVICE_UNAVAILABLE",nil,[NSBundle mainBundle],@"Blio was not able to obtain the purchased book; the server may be temporarily unavailable. Please try again later.",@"Alert message shown when the URLForBookWithID: call fails.")
										delegate:nil 
							   cancelButtonTitle:nil
							   otherButtonTitles:@"OK", nil];
			return nil;
		}
		else if ( [[bodyPart RequestDownloadWithTokenResult].ReturnCode intValue] == 100 ) { 
			NSString* url = [bodyPart RequestDownloadWithTokenResult].Url;
//			NSLog(@"Book download url is %@",url);
			return [NSURL URLWithString:url];
		}
		else {
			NSLog(@"DownloadRequest error: %@",[bodyPart RequestDownloadWithTokenResult].Message);
			if ([[bodyPart RequestDownloadWithTokenResult].Message rangeOfString:@"does not own"].location != NSNotFound) {
				[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"An Error Has Occurred...",@"\"An Error Has Occurred...\" alert message title") 
											 message:[bodyPart RequestDownloadWithTokenResult].Message
											delegate:nil 
								   cancelButtonTitle:nil
								   otherButtonTitles:@"OK", nil];				
			}
			else {
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"An Error Has Occurred...",@"\"An Error Has Occurred...\" alert message title") 
										 message:NSLocalizedStringWithDefaultValue(@"DOWNLOADURL_SERVICE_UNAVAILABLE",nil,[NSBundle mainBundle],@"Blio was not able to obtain the purchased book; the server may be temporarily unavailable. Please try again later.",@"Alert message shown when the URLForBookWithID: call fails.")
										delegate:nil 
							   cancelButtonTitle:nil
							   otherButtonTitles:@"OK", nil];
			}
			return nil;
		}
	}
	return nil;
}
- (void)getContentMetaDataFromISBN:(NSString*)isbn {
	ContentCafeSoap *cafeBinding = [[ContentCafe ContentCafeSoap] retain];
	cafeBinding.logXMLInOut = YES;
//	ContentCafe_Single* singleRequest = [[ContentCafe_Single new] autorelease];
//	singleRequest.userID = @"KNFB98704"; 
//	singleRequest.password = @"CC19811";
//	singleRequest.key = isbn;
//	singleRequest.content = @"ProductDetail";
//	ContentCafeSoapResponse* response = [cafeBinding SingleUsingParameters:singleRequest];

	ContentCafe_XmlClass * xmlRequest = [[ContentCafe_XmlClass new] autorelease];
	xmlRequest.ContentCafe = [[[ContentCafe_ContentCafeXML alloc] init] autorelease];
	xmlRequest.ContentCafe.RequestItems = [[[ContentCafe_RequestItems alloc] init] autorelease];
	xmlRequest.ContentCafe.RequestItems.UserID = @"KNFB98704";
	xmlRequest.ContentCafe.RequestItems.Password = @"CC19811";
	ContentCafe_RequestItem * xmlRequestItem = [[[ContentCafe_RequestItem alloc] init] autorelease];
	xmlRequestItem.Key = isbn;
//	xmlRequestItem.Key = [[[ContentCafe_Key alloc] init] autorelease];
//	xmlRequestItem.Key.Type = ContentCafe_KeyType_ISBN;
//	xmlRequestItem.Key.Original = isbn;
	[xmlRequestItem.Content addObject:@"ProductDetail"];
	[xmlRequest.ContentCafe.RequestItems.RequestItem addObject:xmlRequestItem];
	[cafeBinding XmlClassAsyncUsingParameters:xmlRequest delegate:contentCafeDelegate];
	[cafeBinding release];
}

#pragma mark -
#pragma mark DigitalLockerConnectionDelegate methods

- (void)connectionDidFinishLoading:(DigitalLockerConnection *)aConnection {
//	NSLog(@"BlioOnlineStoreHelper connectionDidFinishLoading...");
	if ([aConnection.Request.Method isEqualToString:DigitalLockerMethodLogin]) {
		if (aConnection.digitalLockerResponse.ReturnCode == 0 || aConnection.digitalLockerResponse.ReturnCode == 301 ) {
			DigitalLockerResponseOutputDataRegistration * OutputDataRegistration = (DigitalLockerResponseOutputDataRegistration*)(aConnection.digitalLockerResponse.OutputData);
			self.userNum = OutputDataRegistration.UserNum;
			[self retrieveTokenWithUsername:currentUsername password:currentPassword];
		}
		else {
			[delegate storeHelper:self receivedLoginResult:BlioLoginResultInvalidPassword];
		}
	}
	
	[aConnection release];
}

- (void)connection:(DigitalLockerConnection *)aConnection didFailWithError:(NSError *)error {
	[delegate storeHelper:self receivedLoginResult:BlioLoginResultError];
	[aConnection release];
}


@end
