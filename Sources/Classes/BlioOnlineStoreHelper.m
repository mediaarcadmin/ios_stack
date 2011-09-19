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
		forceLoginDisplayUponFailure = NO;
#ifdef TEST_MODE
		self.storeURL = @"http://mobile.theretailerplace.net/";
#else	
		self.storeURL = @"https://mobile.blioreader.com/";
#endif
		NSLog(@"initializing BlioOnlineStoreHelper with URL: %@",self.storeURL);
		
	}
	return self;
}
-(void) dealloc {
	[bookVaultDelegate release];
	[contentCafeDelegate release];
	if (_isbns) [_isbns release];
	if (_BookOwnershipInfoArray) [_BookOwnershipInfoArray release];
	[super dealloc];
}
-(void)buyBookWithSourceSpecificID:(NSString*)sourceSpecificID {
	NSLog(@"buyBookWithSourceSpecificID: %@",sourceSpecificID);
	NSString * modifiedID = sourceSpecificID;
	if ([sourceSpecificID length] > 2 && [[[sourceSpecificID substringToIndex:2] lowercaseString] isEqualToString:@"bk"]) {
		modifiedID = [sourceSpecificID substringFromIndex:2];
	}
	
	NSString * fullURL = [NSString stringWithFormat:@"%@bliostore/BTKEY=%@/detail.html", self.storeURL,modifiedID];
	NSURL* url = [[[NSURL alloc] initWithString:fullURL] autorelease];
	[[UIApplication sharedApplication] openURL:url];	
}
- (void)loginWithUsername:(NSString*)user password:(NSString*)password {
	if (currentUsername) [currentUsername release];
	if (currentPassword) [currentPassword release];
    currentUsername = [user retain];
	currentPassword = [password retain];
//	NSLog(@"self.userNum: %i",self.userNum);
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
-(NSString*)loginHostname {
	NSURL * loginURL = nil; 
#ifdef TEST_MODE
	loginURL = [NSURL URLWithString:DigitalLockerGatewayURLTest];
#else	
	loginURL = [NSURL URLWithString:DigitalLockerGatewayURLProduction];
#endif
	return [loginURL host];
}
-(void)retrieveTokenWithUsername:(NSString*)user password:(NSString*)password {
//	NSLog(@"%@", NSStringFromSelector(_cmd));
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
				[[BlioStoreManager sharedInstance] saveUsername:currentUsername password:currentPassword sourceID:self.sourceID];	
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
				if (_BookOwnershipInfoArray) {
					[_BookOwnershipInfoArray release]; // release old set of ISBNs
					_BookOwnershipInfoArray = nil;
				}
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
	else if ([response.responseType isEqualToString:BlioBookVaultResponseTypeVaultContentsWithTokenEx]) {
		NSLog(@"responseType: BlioBookVaultResponseTypeVaultContentsWithTokenEx");
		NSArray *responseBodyParts = response.bodyParts;
		for(id bodyPart in responseBodyParts) {
			NSLog(@"bodyPart class: %@",[[bodyPart class] description]);
			if ([bodyPart isKindOfClass:[SOAPFault class]]) {
				NSString* err = ((SOAPFault *)bodyPart).simpleFaultString;
				NSLog(@"SOAP error for VaultContents: %@",err);
				// TODO: Message
				return;
			}
			else if ( [[bodyPart VaultContentsWithTokenExResult].ReturnCode intValue] == 300 ) { 
				if (_isbns) {
					[_isbns release]; // release old set of ISBNs
					_isbns = nil;
				}
				if (_BookOwnershipInfoArray) [_BookOwnershipInfoArray release]; // release old set of ISBNs
				_BookOwnershipInfoArray = [[bodyPart VaultContentsWithTokenExResult].Contents.BookOwnershipInfo retain];
			}
			else {
				NSLog(@"VaultContents error: %@",[bodyPart VaultContentsWithTokenResult].Message);
				// TODO: Message
				return;
			}
		}
		// add new book entries to PersistentStore as appropriate
		NSLog(@"_BookOwnershipInfoArray count: %i",[_BookOwnershipInfoArray count]);
		newISBNs = 0;
		responseCount = 0;
		successfulResponseCount = 0;

//		NSLog(@"DEBUGGING LOOP:");
//		for (BookVault_BookOwnershipInfo * bookOwnershipInfo in _BookOwnershipInfoArray) {
//			NSLog(@"book in question ISBN: %@",bookOwnershipInfo.ISBN);
//			NSLog(@"bookOwnershipInfo productType: %i",[bookOwnershipInfo.ProductTypeId intValue]);
//		}
		
		for (BookVault_BookOwnershipInfo * bookOwnershipInfo in _BookOwnershipInfoArray) {
			
			// check to see if BlioBook record is already in the persistent store
			BlioBook * preExistingBook = [[BlioStoreManager sharedInstance].processingDelegate bookWithSourceID:self.sourceID ISBN:bookOwnershipInfo.ISBN];
			if (preExistingBook == nil) {
				newISBNs++;
				[self getContentMetaDataFromISBN:bookOwnershipInfo.ISBN];
			}
			else if (([[preExistingBook valueForKey:@"productType"] intValue] == BlioProductTypePreview && [bookOwnershipInfo.ProductTypeId intValue] == BlioProductTypeFull)
                     || ([[preExistingBook valueForKey:@"transactionType"] intValue] == BlioTransactionTypeLend && ([bookOwnershipInfo.ProductTypeId intValue] == BlioTransactionTypeSale || [bookOwnershipInfo.ProductTypeId intValue] == BlioTransactionTypeSaleFromPreorder || [bookOwnershipInfo.ProductTypeId intValue] == BlioTransactionTypePromotion || [bookOwnershipInfo.ProductTypeId intValue] == BlioTransactionTypeFree))) {
                
				[[BlioStoreManager sharedInstance].processingDelegate deleteBook:preExistingBook shouldSave:YES];
				newISBNs++;
				[self getContentMetaDataFromISBN:bookOwnershipInfo.ISBN];
			}
			else {
				NSLog(@"We already have ISBN: %@ in our persistent store, no need to get meta data for this item.",bookOwnershipInfo.ISBN);	
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
			NSLog(@"SOAP error for ContentCafe_XmlClassResponse: %@",err);
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
				BlioProductType aProductType = BlioProductTypeFull;
                BlioTransactionType aTransactionType = BlioTransactionTypeNotSpecified;
                NSDate * anExpirationDate = nil;
				if (_BookOwnershipInfoArray) {
					for (BookVault_BookOwnershipInfo * bookOwnershipInfo in _BookOwnershipInfoArray) {
						if ([[productItem ISBN] isEqualToString:bookOwnershipInfo.ISBN]) {
							if (bookOwnershipInfo.ProductTypeId) aProductType = [bookOwnershipInfo.ProductTypeId intValue];
							if (bookOwnershipInfo.TransactionType) {
                                if ([bookOwnershipInfo.TransactionType isEqualToString:@"SAL"]) aTransactionType = BlioTransactionTypeSale;
                                else if ([bookOwnershipInfo.TransactionType isEqualToString:@"PRO"]) aTransactionType = BlioTransactionTypePromotion;
                                else if ([bookOwnershipInfo.TransactionType isEqualToString:@"TST"]) aTransactionType = BlioTransactionTypeTest;
                                else if ([bookOwnershipInfo.TransactionType isEqualToString:@"LND"]) aTransactionType = BlioTransactionTypeLend;
                                else if ([bookOwnershipInfo.TransactionType isEqualToString:@"FRE"]) aTransactionType = BlioTransactionTypeFree;
                                else if ([bookOwnershipInfo.TransactionType isEqualToString:@"PRE"]) aTransactionType = BlioTransactionTypePreorder;
                                else if ([bookOwnershipInfo.TransactionType isEqualToString:@"PSL"]) aTransactionType = BlioTransactionTypeSaleFromPreorder;
                            }
                            NSLog(@"bookOwnershipInfo.ExpirationDate: %@",bookOwnershipInfo.ExpirationDate);
                            if (bookOwnershipInfo.ExpirationDate) {
                                NSString *dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
                                NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
                                [formatter setDateFormat: dateFormat];
                                anExpirationDate = [formatter dateFromString:bookOwnershipInfo.ExpirationDate];
                            }                

							break;
						}
					}
				}
				NSLog(@"aProductType: %i",aProductType);
				NSLog(@"aTransactionType: %i",aTransactionType);
				NSLog(@"anExpirationDate: %@",anExpirationDate);
				[[BlioStoreManager sharedInstance].processingDelegate enqueueBookWithTitle:title 
																				   authors:authors   
																				 coverPath:coverURL
																				  ePubPath:nil 
																				   pdfPath:nil 
																				   xpsPath:nil
																			  textFlowPath:nil 
																			 audiobookPath:nil 
																				  sourceID:BlioBookSourceOnlineStore 
																		  sourceSpecificID:[productItem BTKey]
																					  ISBN:[productItem ISBN]
																			   productType:aProductType
                                                                           transactionType:aTransactionType 
                                                                            expirationDate:anExpirationDate
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
	if (responseCount == newISBNs || newISBNs == 0) { 
		NSString * ISBNMetadataResponseAlertText = nil;
		if (successfulResponseCount == 0 && newISBNs > 0) {
			// we didn't get any successful responses, though we have a need for ISBN metadata.
			ISBNMetadataResponseAlertText = NSLocalizedStringWithDefaultValue(@"ISBN_METADATA_ALL_ATTEMPTS_FAILED",nil,[NSBundle mainBundle],@"Your latest purchases can't be retrieved at this time. Please try logging in again later.",@"Alert message when all attempts to access the ISBN meta-data web service fail.");
		}
		else if (successfulResponseCount < newISBNs) {
			// we got some successful responses, though not all for the new ISBNs.
			ISBNMetadataResponseAlertText = NSLocalizedStringWithDefaultValue(@"ISBN_METADATA_SOME_ATTEMPTS_FAILED",nil,[NSBundle mainBundle],@"Not all of your latest purchases can be retrieved at this time. Please try logging in again later.",@"Alert message when some but not all attempts to access the ISBN meta-data web service fail.");
		}
		if (ISBNMetadataResponseAlertText != nil) {
			// show alert box
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Server Error",@"\"Server Error\" alert message title")
										 message:ISBNMetadataResponseAlertText
										delegate:nil 
							   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
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
	NSMutableDictionary * usersDictionary = [[[[NSUserDefaults standardUserDefaults] dictionaryForKey:kBlioUsersDictionaryDefaultsKey] mutableCopy] autorelease];
	if (usersDictionary) {
		NSMutableDictionary * currentUserDictionary = [[[usersDictionary objectForKey:[NSString stringWithFormat:@"%i",[self userNum]]] mutableCopy] autorelease];
		if (currentUserDictionary && [currentUserDictionary objectForKey:kBlioDeviceRegisteredDefaultsKey]) {
			return [[currentUserDictionary objectForKey:kBlioDeviceRegisteredDefaultsKey] intValue];
		}
	}
	return 0;
}
-(BOOL) setDeviceRegisteredSettingOnly:(BlioDeviceRegisteredStatus)targetStatus {
	NSMutableDictionary * usersDictionary = [[[[NSUserDefaults standardUserDefaults] dictionaryForKey:kBlioUsersDictionaryDefaultsKey] mutableCopy] autorelease];
	if (!usersDictionary) usersDictionary = [NSMutableDictionary dictionary];
	NSMutableDictionary * currentUserDictionary = [[[usersDictionary objectForKey:[NSString stringWithFormat:@"%i",[self userNum]]] mutableCopy] autorelease];
	if (!currentUserDictionary) currentUserDictionary = [NSMutableDictionary dictionary];				
	[currentUserDictionary setObject:[NSNumber numberWithInt:targetStatus] forKey:kBlioDeviceRegisteredDefaultsKey];
	[usersDictionary setObject:currentUserDictionary forKey:[NSString stringWithFormat:@"%i",[self userNum]]];
	[[NSUserDefaults standardUserDefaults] setObject:usersDictionary forKey:kBlioUsersDictionaryDefaultsKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
	return YES;
}
-(BOOL) setDeviceRegistered:(BlioDeviceRegisteredStatus)targetStatus {
	if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
		NSString * internetMessage = NSLocalizedStringWithDefaultValue(@"INTERNET_REQUIRED_DEREGISTRATION",nil,[NSBundle mainBundle],@"An internet connection is required to deregister this device.",@"Alert message when the user tries to deregister the device without an Internet connection.");
		if (targetStatus == BlioDeviceRegisteredStatusRegistered) internetMessage = NSLocalizedStringWithDefaultValue(@"INTERNET_REQUIRED_DEREGISTRATION",nil,[NSBundle mainBundle],@"An internet connection is required to deregister this device.",@"Alert message when the user tries to deregister the device without an Internet connection.");
		
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Internet Connection Not Found",@"\"Internet Connection Not Found\" alert message title")
									 message:internetMessage
									delegate:nil 
						   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
						   otherButtonTitles: nil];		
		return NO;
	}
	if (![self hasValidToken]) {
		NSString * loginMessage = NSLocalizedStringWithDefaultValue(@"LOGIN_REQUIRED_DEREGISTRATION",nil,[NSBundle mainBundle],@"You must be logged in to deregister this device.",@"Alert message when the user tries to deregister the device without being logged in.");
		if (targetStatus == BlioDeviceRegisteredStatusRegistered) loginMessage = NSLocalizedStringWithDefaultValue(@"INTERNET_REQUIRED_REGISTRATION",nil,[NSBundle mainBundle],@"You must be logged in to register this device.",@"Alert message when the user tries to register the device without being logged in.");
		
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Not Logged In",@"\"Not Logged In\" alert message title")
									 message:loginMessage
									delegate:nil 
						   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
						   otherButtonTitles: nil];		
		return NO;
	}
	BlioDrmSessionManager* drmSessionManager = [[BlioDrmSessionManager alloc] initWithBookID:nil];
	if ( targetStatus == BlioDeviceRegisteredStatusRegistered ) {
		if ( ![drmSessionManager joinDomain:self.token domainName:@"novel" alertAlways:YES] ) {
			// Alert is shown by the drmSessionManager, to display error code.
			[drmSessionManager release];
			return NO;
		} 
	}
	else {
		if ( ![drmSessionManager leaveDomain:self.token] ) {
			// Alert shown in drmSessionManager to display error code.
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
//	NSLog(@"%@", NSStringFromSelector(_cmd));
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
	vaultBinding.logXMLInOut = YES;
//	BookVault_VaultContentsWithToken* vaultContentsRequest = [[BookVault_VaultContentsWithToken new] autorelease];
	BookVault_VaultContentsWithTokenEx* vaultContentsRequest = [[BookVault_VaultContentsWithTokenEx new] autorelease];
	vaultContentsRequest.token = [[BlioStoreManager sharedInstance] tokenForSourceID:BlioBookSourceOnlineStore]; 
//	[vaultBinding VaultContentsWithTokenAsyncUsingParameters:vaultContentsRequest delegate:bookVaultDelegate];
	[vaultBinding VaultContentsWithTokenExAsyncUsingParameters:vaultContentsRequest delegate:bookVaultDelegate];
	[vaultBinding release];
}
-(NSURL*)URLForBookWithID:(NSString*)sourceSpecificID {
//	NSLog(@"%@", NSStringFromSelector(_cmd));
	BlioBook * book = [[BlioStoreManager sharedInstance].processingDelegate bookWithSourceID:self.sourceID sourceSpecificID:sourceSpecificID];
	BookVaultSoap *vaultBinding = [[BookVault BookVaultSoap] retain];
	vaultBinding.logXMLInOut = YES;
//	BookVault_RequestDownloadWithToken* downloadRequest = [[BookVault_RequestDownloadWithToken new] autorelease];
//	BookVault_RequestDownloadWithTokenEx* downloadRequest = [[BookVault_RequestDownloadWithTokenEx new] autorelease];
	BookVault_RequestClientDownloadWithTokenEx* downloadRequest = [[BookVault_RequestClientDownloadWithTokenEx new] autorelease];
	downloadRequest.token = [[BlioStoreManager sharedInstance] tokenForSourceID:BlioBookSourceOnlineStore]; 
	downloadRequest.isbn = [book valueForKey:@"isbn"];
	downloadRequest.productType = [book valueForKey:@"productType"];
    
    NSString * platform = @"iPhone";
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) platform = @"iPad";
    NSString* version = (NSString*)[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]; // @"CFBundleVersion" for build number
    NSString * model = [[UIDevice currentDevice] model];
    NSString * OSType = [[UIDevice currentDevice] systemName];
    NSString * OSVersion = [[UIDevice currentDevice] systemVersion];
    NSInteger screenWidth = [[UIScreen mainScreen] bounds].size.width;
    NSInteger screenHeight = [[UIScreen mainScreen] bounds].size.height;
    NSString * preferredFormat = @"XPS-EPUB"; // temporary value; is not currently honored.
    
	downloadRequest.clientInfo = [NSString stringWithFormat:@"<ClientInfo><Platform Id=\"%@\" Version=\"%@\"/></ClientInfo>",platform,version];    
	downloadRequest.clientInfo = [NSString stringWithFormat:@"<ClientInfo><Partner Id=\"Apple\"/><Platform Id=\"%@\" Version=\"%@\"/><Device Model=\"%@\" OsType=\"%@\" OsVersion = \"%@\" ScreenWidth=\"%i\" ScreenHeight=\"%i\"/><BookInfo PreferredFormat=\"%@\"/></ClientInfo>",platform,version,model,OSType,OSVersion,screenWidth,screenHeight,preferredFormat];
    NSLog(@"%@",downloadRequest.clientInfo);
    
//	BookVaultSoapResponse* response = [vaultBinding RequestDownloadWithTokenUsingParameters:downloadRequest];
//	BookVaultSoapResponse* response = [vaultBinding RequestDownloadWithTokenExUsingParameters:downloadRequest];
	BookVaultSoapResponse* response = [vaultBinding RequestClientDownloadWithTokenExUsingParameters:downloadRequest];
	[vaultBinding release];
	NSArray *responseBodyParts = response.bodyParts;
	for(id bodyPart in responseBodyParts) {
		if ([bodyPart isKindOfClass:[SOAPFault class]]) {
			NSString* err = ((SOAPFault *)bodyPart).simpleFaultString;
			NSLog(@"SOAP error for VaultContents: %@",err);
			[BlioAlertManager showAlertOfSuppressedType:BlioBookDownloadFailureAlertType
											  title:NSLocalizedString(@"Error Downloading Book",@"\"Error Downloading Book\" alert message title") 
										 message:NSLocalizedStringWithDefaultValue(@"DOWNLOADURL_SERVICE_UNAVAILABLE",nil,[NSBundle mainBundle],@"The server may be temporarily unavailable. Please try again later.",@"Alert message shown when the URLForBookWithID: call fails.")
										delegate:nil 
							   cancelButtonTitle:nil
							   otherButtonTitles:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview"), nil];
			return nil;
		}
		else if ([bodyPart isKindOfClass:[BookVault_RequestDownloadWithTokenResponse class]]) {
			if ( [[bodyPart RequestDownloadWithTokenResult].ReturnCode intValue] == 100 ) { 
				[BlioAlertManager removeSuppressionForAlertType:BlioBookDownloadFailureAlertType];
				NSString* url = [bodyPart RequestDownloadWithTokenResult].Url;
				//			NSLog(@"Book download url is %@",url);
				return [NSURL URLWithString:url];
			}
			else {
				NSLog(@"DownloadRequest error: %@",[bodyPart RequestDownloadWithTokenResult].Message);
				if ([[bodyPart RequestDownloadWithTokenResult].Message rangeOfString:@"does not own"].location != NSNotFound) {
					[BlioAlertManager showAlertOfSuppressedType:BlioBookDownloadFailureAlertType
														  title:NSLocalizedString(@"Error Downloading Book",@"\"Error Downloading Book\" alert message title") 
												 message:[bodyPart RequestDownloadWithTokenResult].Message
												delegate:nil 
									   cancelButtonTitle:nil
									   otherButtonTitles:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview"), nil];				
				}
				else {
					[BlioAlertManager showAlertOfSuppressedType:BlioBookDownloadFailureAlertType
														  title:NSLocalizedString(@"Error Downloading Book",@"\"Error Downloading Book\" alert message title") 
														message:NSLocalizedStringWithDefaultValue(@"DOWNLOADURL_SERVICE_UNAVAILABLE",nil,[NSBundle mainBundle],@"The server may be temporarily unavailable. Please try again later.",@"Alert message shown when the URLForBookWithID: call fails.")
													   delegate:nil 
											  cancelButtonTitle:nil
											  otherButtonTitles:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview"), nil];
				}
				return nil;
			}
		}
		else if ([bodyPart isKindOfClass:[BookVault_RequestDownloadWithTokenExResponse class]]) {
			if ( [[bodyPart RequestDownloadWithTokenExResult].ReturnCode intValue] == 100 ) { 
				[BlioAlertManager removeSuppressionForAlertType:BlioBookDownloadFailureAlertType];
				NSString* url = [bodyPart RequestDownloadWithTokenExResult].Url;
				//			NSLog(@"Book download url is %@",url);
				return [NSURL URLWithString:url];
			}
			else {
				NSLog(@"DownloadRequest error: %@",[bodyPart RequestDownloadWithTokenExResult].Message);
				if ([[bodyPart RequestDownloadWithTokenExResult].Message rangeOfString:@"does not own"].location != NSNotFound) {
					[BlioAlertManager showAlertOfSuppressedType:BlioBookDownloadFailureAlertType\
                                                          title:NSLocalizedString(@"Error Downloading Book",@"\"Error Downloading Book\" alert message title") 
                                                        message:[bodyPart RequestDownloadWithTokenExResult].Message
                                                       delegate:nil 
                                              cancelButtonTitle:nil
                                              otherButtonTitles:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview"), nil];				
				}
				else {
					[BlioAlertManager showAlertOfSuppressedType:BlioBookDownloadFailureAlertType
														  title:NSLocalizedString(@"Error Downloading Book",@"\"Error Downloading Book\" alert message title") 
														message:NSLocalizedStringWithDefaultValue(@"DOWNLOADURL_SERVICE_UNAVAILABLE",nil,[NSBundle mainBundle],@"The server may be temporarily unavailable. Please try again later.",@"Alert message shown when the URLForBookWithID: call fails.")
													   delegate:nil 
											  cancelButtonTitle:nil
											  otherButtonTitles:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview"), nil];
				}
				return nil;
			}
		}
		else if ([bodyPart isKindOfClass:[BookVault_RequestClientDownloadWithTokenExResponse class]]) {
			if ( [[bodyPart RequestClientDownloadWithTokenExResult].ReturnCode intValue] == 100 ) { 
				[BlioAlertManager removeSuppressionForAlertType:BlioBookDownloadFailureAlertType];
				NSString* url = [bodyPart RequestClientDownloadWithTokenExResult].Url;
				//			NSLog(@"Book download url is %@",url);
				return [NSURL URLWithString:url];
			}
			else {
				NSLog(@"DownloadRequest error: %@",[bodyPart RequestClientDownloadWithTokenExResult].Message);
				if ([[bodyPart RequestClientDownloadWithTokenExResult].Message rangeOfString:@"does not own"].location != NSNotFound) {
					[BlioAlertManager showAlertOfSuppressedType:BlioBookDownloadFailureAlertType\
                                                          title:NSLocalizedString(@"Error Downloading Book",@"\"Error Downloading Book\" alert message title") 
                                                        message:[bodyPart RequestClientDownloadWithTokenExResult].Message
                                                       delegate:nil 
                                              cancelButtonTitle:nil
                                              otherButtonTitles:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview"), nil];				
				}
				else {
					[BlioAlertManager showAlertOfSuppressedType:BlioBookDownloadFailureAlertType
														  title:NSLocalizedString(@"Error Downloading Book",@"\"Error Downloading Book\" alert message title") 
														message:NSLocalizedStringWithDefaultValue(@"DOWNLOADURL_SERVICE_UNAVAILABLE",nil,[NSBundle mainBundle],@"The server may be temporarily unavailable. Please try again later.",@"Alert message shown when the URLForBookWithID: call fails.")
													   delegate:nil 
											  cancelButtonTitle:nil
											  otherButtonTitles:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview"), nil];
				}
				return nil;
			}
		}
	}
	return nil;
}
- (void)getContentMetaDataFromISBN:(NSString*)isbn {
	NSLog(@"Getting Content MetaData for ISBN: %@",isbn);
	ContentCafeSoap *cafeBinding = [[ContentCafe ContentCafeSoap] retain];
	cafeBinding.logXMLInOut = NO;
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
	[delegate storeHelper:self receivedLoginResult:BlioLoginResultConnectionError];
	[aConnection release];
}


@end
