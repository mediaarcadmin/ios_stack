//
//  BlioBookVaultManager.m
//  BlioApp
//
//  Created by Arnold Chien on 4/13/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import "BlioBookVaultManager.h"
#import "BlioContentCafe.h"
#import "BlioBookVault.h"
#import "BlioAlertManager.h"

@implementation BlioBookVaultManager

@synthesize loginManager, processingManager,managedObjectContext;
@synthesize isbns = _isbns;


- (id)init
{
	self = [super init];
	if (self)
	{
		self.loginManager = [[[BlioLoginManager alloc] init] autorelease];
		_isbns = nil;
	}
	
	return self;
}
// TODO: have this method utilized by NSOperation sub-class
- (NSURL*)URLForPaidBook:(NSString*)isbn {
	BookVaultSoap *vaultBinding = [[BookVault BookVaultSoap] retain];
	vaultBinding.logXMLInOut = YES;
	BookVault_RequestDownloadWithToken* downloadRequest = [[BookVault_RequestDownloadWithToken new] autorelease];
	downloadRequest.token = [self.loginManager token]; 
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
			NSLog(@"Book download url is %s",url);
			return [NSURL URLWithString:url];
		}
		else {
			NSLog(@"DownloadRequest error: %s",[bodyPart RequestDownloadResult].Message);
			// cancel download
			// TODO: Message
			return nil;
		}
	}
	return nil;
}

-(BOOL)hasValidToken {
	return [self.loginManager hasValidToken];
}
- (ContentCafe_ProductItem*)getContentMetaDataFromISBN:(NSString*)isbn {
	ContentCafeSoap *cafeBinding = [[ContentCafe ContentCafeSoap] retain];
	cafeBinding.logXMLInOut = YES;
	ContentCafe_Single* singleRequest = [[ContentCafe_Single new] autorelease];
	singleRequest.userID = @"KNFB98704"; 
	singleRequest.password = @"CC19811";
	singleRequest.key = isbn;
	singleRequest.content = @"ProductDetail";
	ContentCafeSoapResponse* response = [cafeBinding SingleUsingParameters:singleRequest];
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
			NSLog(@"SOAP error for ContentCafeSingle: %s",err);
			// TODO: Message
			return nil;
		}
		else if ( (requestItems = [[bodyPart ContentCafe] RequestItems]) ) { 
			ContentCafe_RequestItem* requestItem = (ContentCafe_RequestItem*)[[requestItems RequestItem] objectAtIndex:0];
			ContentCafe_ProductItem* productItem =(ContentCafe_ProductItem*)[[[requestItem ProductItems] ProductItem] objectAtIndex:0];
			return productItem;
		}
		else {
			NSLog(@"ContentCafeSingle error.");
			// TODO: Message
		}
		
	}
	return nil;
}

- (void)archiveBooks {
	if (!self.processingManager) {
		NSLog(@"ERROR: no processingManager set for BlioBookVaultManager! Aborting archiveBooks...");
		return;
	}
	if (![self fetchBooksFromServer]) {
		NSLog(@"ERROR: could not fetch ISBNs from the server!");
		return;
	}
	// add new book entries to PersistentStore as appropriate
	NSInteger successfulResponseCount = 0;
	NSInteger newISBNs = 0;
	for (NSString * isbn in _isbns) {
		
		// check to see if BlioMockBook record is already in the persistent store
		
		NSManagedObjectContext *moc = [self managedObjectContext];
				
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[NSEntityDescription entityForName:@"BlioMockBook" inManagedObjectContext:moc]];
		[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"sourceID == %@ && sourceSpecificID == %@",[NSNumber numberWithInt:BlioBookSourceOnlineStore],isbn]];
		
		NSError *errorExecute = nil;
		NSArray *results = [moc executeFetchRequest:fetchRequest error:&errorExecute]; 
		[fetchRequest release];
		if (errorExecute) {
			NSLog(@"Error searching for paid book in MOC. %@, %@", errorExecute, [errorExecute userInfo]);
			break;
		}
		if ([results count] == 0) {
			newISBNs++;
			ContentCafe_ProductItem* productItem = [self getContentMetaDataFromISBN:isbn];
			if (productItem) {
				successfulResponseCount++;
				// TODO: put in a book for display in the vault.
				NSString* title = [[productItem Title] Value];
				NSString* author = [productItem Author];
				NSString* coverURL = [NSString stringWithFormat:@"http://images.btol.com/cc2images/Image.aspx?SystemID=knfb&IdentifierID=I&IdentifierValue=%@&Source=BT&Category=FC&Sequence=1&Size=L&NotFound=S",isbn];
				NSLog(@"Title: %@", title);
				NSLog(@"Author: %@", author);
				NSLog(@"Cover: %@", coverURL);
				
				[self.processingManager enqueueBookWithTitle:title 
													 authors:[NSArray arrayWithObject:author] 
													coverURL:[NSURL URLWithString:coverURL] 
													 ePubURL:nil 
													  pdfURL:nil 
												 textFlowURL:nil 
												audiobookURL:nil 
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
- (BOOL)fetchBooksFromServer {
	BookVaultSoap *vaultBinding = [[BookVault BookVaultSoap] retain];
	//vaultBinding.logXMLInOut = YES;
	BookVault_VaultContentsWithToken* vaultContentsRequest = [[BookVault_VaultContentsWithToken new] autorelease];
	vaultContentsRequest.token = [self.loginManager token]; 
	BookVaultSoapResponse* response = [vaultBinding VaultContentsWithTokenUsingParameters:vaultContentsRequest];
	[vaultBinding release];
	NSArray *responseBodyParts = response.bodyParts;
	for(id bodyPart in responseBodyParts) {
		if ([bodyPart isKindOfClass:[SOAPFault class]]) {
			NSString* err = ((SOAPFault *)bodyPart).simpleFaultString;
			NSLog(@"SOAP error for VaultContents: %s",err);
			// TODO: Message
			return NO;
		}
		else if ( [[bodyPart VaultContentsWithTokenResult].ReturnCode intValue] == 300 ) { 
			if (_isbns) [_isbns release]; // release old set of ISBNs
			_isbns = [[bodyPart VaultContentsWithTokenResult].Contents.string retain];
			return YES;
		}
		else {
			NSLog(@"VaultContents error: %s",[bodyPart VaultContentsWithTokenResult].Message);
			// TODO: Message
			return NO;
		}
	}
	return NO;
}
/*
-(void) testDownloadAllContent {
	// TODO: Remove from the isbn list the isbns that are already on the device.
	for (id isbn in _isbns) {
		[self getContent:isbn];
		// For testing
		[self downloadBook:isbn];
	}	
}
 */
- (void)dealloc {
	if (_isbns) [_isbns release];
	self.loginManager = nil;
	self.processingManager = nil;
	self.managedObjectContext = nil;
    [super dealloc];
}

@end
