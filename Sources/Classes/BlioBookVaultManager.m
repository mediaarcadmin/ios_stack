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


- (id)init
{
	self = [super init];
	if (self)
	{
		self.loginManager = [[BlioLoginManager alloc] init];
		
	}
	
	return self;
}

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

- (void)getContent:(NSString*)isbn {
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
	ContentCafe_RequestItems* requestItems;
	for(id bodyPart in responseBodyParts) {
		if ([bodyPart isKindOfClass:[SOAPFault class]]) {
			NSString* err = ((SOAPFault *)bodyPart).simpleFaultString;
			NSLog(@"SOAP error for ContentCafeSingle: %s",err);
			// TODO: Message
			return;
		}
		else if ( (requestItems = [[bodyPart ContentCafe] RequestItems]) ) { 
			ContentCafe_RequestItem* requestItem = (ContentCafe_RequestItem*)[[requestItems RequestItem] objectAtIndex:0];
			ContentCafe_ProductItem* productItem =(ContentCafe_ProductItem*)[[[requestItem ProductItems] ProductItem] objectAtIndex:0];
			// TODO: put in a book for display in the vault.
			NSString* title = [[productItem Title] Value];
			NSString* author = [productItem Author];
			NSString* coverURL = [NSString stringWithFormat:@"http://images.btol.com/cc2images/Image.aspx?SystemID=knfb&IdentifierID=I&IdentifierValue=%@&Source=BT&Category=FC&Sequence=1&Size=L&NotFound=S",isbn];
			NSLog(@"Title: %s", title);
			NSLog(@"Author: %s", author);
			NSLog(@"Cover: %s", coverURL);
		}
		else {
			NSLog(@"ContentCafeSingle error.");
			// TODO: Message
		}
		
	}		
}

- (void)archiveBooks {
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
			return;
		}
		else if ( [[bodyPart VaultContentsWithTokenResult].ReturnCode intValue] == 300 ) { 
			isbns = [bodyPart VaultContentsWithTokenResult].Contents.string;
		}
		else {
			NSLog(@"VaultContents error: %s",[bodyPart VaultContentsWithTokenResult].Message);
			// TODO: Message
			return;
		}
	}
	// TODO: Remove from the isbn list the isbns that are already on the device.
	for (id isbn in isbns) {
		[self getContent:isbn];
		// For testing
		[self downloadBook:isbn];
	}
	
	
}

@end
