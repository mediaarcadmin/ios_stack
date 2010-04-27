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

@implementation BlioBookVaultManager

@synthesize loginManager;
@synthesize processingManager;
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
// TODO: refactor as NSOperation
- (void)downloadBook:(NSString*)isbn {
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
			return;
		}
		else if ( [[bodyPart RequestDownloadWithTokenResult].ReturnCode intValue] == 100 ) { 
			NSString* url = [bodyPart RequestDownloadWithTokenResult].Url;
			NSLog(@"Book download url is %s",url);
		}
		else {
			NSLog(@"DownloadRequest error: %s",[bodyPart RequestDownloadResult].Message);
			// cancel download
			// TODO: Message
			return;
		}
	}
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
	for (NSString * isbn in _isbns) {
		ContentCafe_ProductItem* productItem = [self getContentMetaDataFromISBN:isbn];
		if (productItem) {
			// TODO: put in a book for display in the vault.
			NSString* title = [[productItem Title] Value];
			NSString* author = [productItem Author];
			NSString* coverURL = [NSString stringWithFormat:@"http://images.btol.com/cc2images/Image.aspx?SystemID=knfb&IdentifierID=I&IdentifierValue=%@&Source=BT&Category=FC&Sequence=1&Size=L&NotFound=S",isbn];
			NSLog(@"Title: %@", title);
			NSLog(@"Author: %@", author);
			NSLog(@"Cover: %@", coverURL);
			
			// check to see if title is already in persistent store
			
			
			[self.processingManager enqueueBookWithTitle:title 
												 authors:[NSArray arrayWithObject:author] 
												coverURL:[NSURL URLWithString:coverURL] 
												 ePubURL:nil 
												  pdfURL:nil 
											 textFlowURL:nil 
											audiobookURL:nil 
												sourceID:kBlioOnlineStoreSourceID 
										sourceSpecificID:isbn
										 placeholderOnly:YES
			 ];
		}
		else {

		}
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
    [super dealloc];
}

@end
