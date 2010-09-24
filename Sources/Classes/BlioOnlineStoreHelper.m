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

#define KNFB_STORE 12151
#define HP_STORE 12308
#define TOSHIBA_STORE 12309
#define DELL_STORE 12327

@interface BlioOnlineStoreHelper (PRIVATE)
- (ContentCafe_ProductItem*)getContentMetaDataFromISBN:(NSString*)isbn;
- (BOOL)fetchBookISBNArrayFromServer;
@end

@implementation BlioOnlineStoreHelper

- (id) init {
	if((self = [super init])) {
		self.sourceID = BlioBookSourceOnlineStore;
		self.storeTitle = @"Blio Online Store";
	}
	return self;
}

- (void)loginWithUsername:(NSString*)user password:(NSString*)password {
	BookVaultSoap *vaultBinding = [[BookVault BookVaultSoap] retain];
	//vaultBinding.logXMLInOut = YES;
	self.username = user;
	BookVault_Login *loginRequest = [[BookVault_Login new] autorelease];
	loginRequest.username = user;	
	loginRequest.password = password; 
	loginRequest.siteId =  [NSNumber numberWithInt:HP_STORE];
	[vaultBinding LoginAsyncUsingParameters:loginRequest delegate:self];
	[vaultBinding release];
}
- (void) operation:(BookVaultSoapOperation *)operation completedWithResponse:(BookVaultSoapResponse *)response {
	NSArray *responseBodyParts = response.bodyParts;
	for(id bodyPart in responseBodyParts) {
		NSLog(@"bodyPart: %@",bodyPart);
	}
	for(id bodyPart in responseBodyParts) {
		NSLog(@"[[bodyPart LoginResult].ReturnCode intValue]: %i",[[bodyPart LoginResult].ReturnCode intValue]);
		if ([bodyPart isKindOfClass:[SOAPFault class]]) {
			NSString* err = ((SOAPFault *)bodyPart).simpleFaultString;
			NSLog(@"SOAP error for login: %s",err);
			[delegate storeHelper:self receivedLoginResult:BlioLoginResultError];
			return;
		}
		else if ( [[bodyPart LoginResult].ReturnCode intValue] == 200 ) { 
			self.isLoggedIn = YES;
			self.token = [bodyPart LoginResult].Token;
			self.timeout = [[NSDate date] addTimeInterval:(NSTimeInterval)[[bodyPart LoginResult].Timeout floatValue]];
			NSLog(@"timeout: %@",self.timeout);


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
	// TODO: make the string key value dynamic
}
-(BOOL)hasValidToken {
	if (self.token == nil) return NO;
	if ([self.timeout compare:[NSDate date]] == NSOrderedDescending) return YES;
	return NO;
}
-(BlioDeviceRegisteredStatus)deviceRegistered {
	return [[NSUserDefaults standardUserDefaults] integerForKey:kBlioDeviceRegisteredDefaultsKey];
}
-(void) setDeviceRegistered:(BlioDeviceRegisteredStatus)status {
	NSLog(@"setDeviceRegistered: %i",status);
	[[NSUserDefaults standardUserDefaults] setInteger:status forKey:kBlioDeviceRegisteredDefaultsKey];
	NSLog(@"deviceRegistered: %i", [self deviceRegistered]);
}
- (void)logout {
	self.token = nil;
	self.isLoggedIn = NO;
	self.username = nil;
	self.timeout = [NSDate distantPast];
}
-(void)retrieveBooks {
	if (![BlioStoreManager sharedInstance].processingDelegate) {
		NSLog(@"ERROR: no processingManager set for BlioOnlineStoreHelper! Aborting archiveBooks...");
		return;
	}
	if (![self fetchBookISBNArrayFromServer]) {
		NSLog(@"ERROR: could not fetch ISBNs from the server!");
		return;
	}
	// add new book entries to PersistentStore as appropriate
	NSInteger successfulResponseCount = 0;
	NSInteger newISBNs = 0;
	NSLog(@"ISBN count: %i",[_isbns count]);
	for (NSString * isbn in _isbns) {
		
		// check to see if BlioBook record is already in the persistent store
		
		if ([[BlioStoreManager sharedInstance].processingDelegate bookWithSourceID:self.sourceID sourceSpecificID:isbn] == nil) {
			newISBNs++;
			ContentCafe_ProductItem* productItem = [self getContentMetaDataFromISBN:isbn];
			if (productItem) {
				successfulResponseCount++;
				NSString* title = [[productItem Title] Value];
				NSString* author = [productItem Author];
				NSString* coverURL = [NSString stringWithFormat:@"http://images.btol.com/cc2images/Image.aspx?SystemID=knfb&IdentifierID=I&IdentifierValue=%@&Source=BT&Category=FC&Sequence=1&Size=L&NotFound=S",isbn];
				NSLog(@"Title: %@", title);
				NSLog(@"Author: %@", author);
				NSLog(@"Cover: %@", coverURL);
				NSLog(@"URL: %@",[[self URLForBookWithID:isbn] absoluteString]);
				NSArray * authors = [NSArray array];
				if (author) {
					authors = [author componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@";"]];
				}
				// TODO: need to discern patterns in how paid books store multiple authors in one string, then parse accordingly into an array.
				[[BlioStoreManager sharedInstance].processingDelegate enqueueBookWithTitle:title 
													 authors:authors   
													coverPath:coverURL
													 ePubPath:nil 
													  pdfPath:nil 
                                                      xpsPath:nil
												 textFlowPath:nil 
												audiobookPath:nil 
													sourceID:BlioBookSourceOnlineStore 
											sourceSpecificID:isbn
											 placeholderOnly:YES
				 ];
			}
			else {

			}			
		}
		else {
			NSLog(@"We already have ISBN: %@ in our persistent store, no need to get meta data for this item.",isbn);
		}
	}
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
									delegate:self 
						   cancelButtonTitle:@"OK"
						   otherButtonTitles: nil];
		//		UIAlertView *errorAlert = [[UIAlertView alloc] 
		//								   initWithTitle:NSLocalizedString(@"We're Sorry...",@"\"We're Sorry...\" alert message title")
		//								   message:ISBNMetadataResponseAlertText
		//								   delegate:self 
		//								   cancelButtonTitle:@"OK"
		//								   otherButtonTitles: nil];
		//		[errorAlert show];
		//		[errorAlert release];		
	}
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
			NSLog(@"SOAP error for VaultContents: %s",err);
			// TODO: Message
			return nil;
		}
		else if ( [[bodyPart RequestDownloadWithTokenResult].ReturnCode intValue] == 100 ) { 
			NSString* url = [bodyPart RequestDownloadWithTokenResult].Url;
			NSLog(@"Book download url is %@",url);
			return [NSURL URLWithString:url];
		}
		else {
			NSLog(@"DownloadRequest error: %s",[bodyPart RequestDownloadWithTokenResult].Message);
			// cancel download
			// TODO: Message
			return nil;
		}
	}
	return nil;
}
- (ContentCafe_ProductItem*)getContentMetaDataFromISBN:(NSString*)isbn {
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
	ContentCafeSoapResponse* response = [cafeBinding XmlClassUsingParameters:xmlRequest];
	
	[cafeBinding release];
	NSArray *responseBodyParts = response.bodyParts;
	if (responseBodyParts == nil) {
		NSLog(@"ERROR: responseBodyParts is nil. response: %@",response);
		return nil;
	}
	ContentCafe_RequestItems* requestItems;
	for(id bodyPart in responseBodyParts) {
		if ([bodyPart isKindOfClass:[SOAPFault class]]) {
			NSString* err = ((SOAPFault *)bodyPart).simpleFaultString;
			NSLog(@"SOAP error for ContentCafe_XmlClassResponse: %s",err);
			// TODO: Message
			return nil;
		}
		else if ( (requestItems = [[bodyPart ContentCafe] RequestItems]) ) { 
			ContentCafe_RequestItem* requestItem = (ContentCafe_RequestItem*)[[requestItems RequestItem] objectAtIndex:0];
			ContentCafe_ProductItem* productItem =(ContentCafe_ProductItem*)[[[requestItem ProductItems] ProductItem] objectAtIndex:0];
			return productItem;
		}
		else {
			NSLog(@"ContentCafe_XmlClassResponse error.");
			// TODO: Message
		}
		
	}
	return nil;
}
- (BOOL)fetchBookISBNArrayFromServer {
	BookVaultSoap *vaultBinding = [[BookVault BookVaultSoap] retain];
	//vaultBinding.logXMLInOut = YES;
	BookVault_VaultContentsWithToken* vaultContentsRequest = [[BookVault_VaultContentsWithToken new] autorelease];
	vaultContentsRequest.token = [[BlioStoreManager sharedInstance] tokenForSourceID:BlioBookSourceOnlineStore]; 
	BookVaultSoapResponse* response = [vaultBinding VaultContentsWithTokenUsingParameters:vaultContentsRequest];
	[vaultBinding release];
	NSArray *responseBodyParts = response.bodyParts;
	for(id bodyPart in responseBodyParts) {
		if ([bodyPart isKindOfClass:[SOAPFault class]]) {
			NSString* err = ((SOAPFault *)bodyPart).simpleFaultString;
			NSLog(@"SOAP error for VaultContents: %@",err);
			// TODO: Message
			return NO;
		}
		else if ( [[bodyPart VaultContentsWithTokenResult].ReturnCode intValue] == 300 ) { 
			if (_isbns) [_isbns release]; // release old set of ISBNs
			_isbns = [[bodyPart VaultContentsWithTokenResult].Contents.string retain];
			return YES;
		}
		else {
			NSLog(@"VaultContents error: %@",[bodyPart VaultContentsWithTokenResult].Message);
			// TODO: Message
			return NO;
		}
	}
	return NO;
}

@end
