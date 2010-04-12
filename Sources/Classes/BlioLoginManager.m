//
//  BlioLoginManager.m
//  BlioApp
//
//  Created by Arnold Chien on 4/5/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import "BlioLoginManager.h"
#import "BlioBookVault.h"
#import "BlioContentCafe.h"

@implementation BlioLoginManager

@synthesize timeout, username, token, isLoggedIn;

- (BlioLoginResult)login:(NSString*)user password:(NSString*)passwd {
	BookVaultSoap *vaultBinding = [[BookVault BookVaultSoap] retain];
	//vaultBinding.logXMLInOut = YES;
	BookVault_Login *loginRequest = [[BookVault_Login new] autorelease];
	loginRequest.username = user;	//@"gordonfrog@gmail.com" account for testing
	loginRequest.password = passwd; //@"Gumby01";  
	loginRequest.siteId =  [NSNumber numberWithInt:12151];		// hard-coded in Windows Blio
	BookVaultSoapResponse * response = [vaultBinding LoginUsingParameters:loginRequest];
	[vaultBinding release];
	NSArray *responseBodyParts = response.bodyParts;
	for(id bodyPart in responseBodyParts) {
		if ([bodyPart isKindOfClass:[SOAPFault class]]) {
			NSString* err = ((SOAPFault *)bodyPart).simpleFaultString;
			NSLog(@"SOAP error for login: %s",err);
			return error;
		}
		else if ( [[bodyPart LoginResult].ReturnCode intValue] == 200 ) { 
			self.isLoggedIn = YES;
			self.username = user;
			self.token = [bodyPart LoginResult].Token;
			self.timeout = [[NSDate date] addTimeInterval:(NSTimeInterval)[[bodyPart LoginResult].Timeout floatValue]];
			return success;
		}
		else if ( [[bodyPart LoginResult].ReturnCode intValue] == 203 ) {
			NSLog(@"Invalid password");
			return invalidPassword;
		}
		else {
			NSLog(@"Login error: %s",[bodyPart LoginResult].Message);
			return error;
		}
	}
	return error;
}

- (void)logout {
	self.token = nil;
	self.isLoggedIn = NO;
	self.username = nil;
	self.timeout = [NSDate distantPast];
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

// This is a separate activity from login, but want to do every time we log in.
- (void)archiveBooks {
	BookVaultSoap *vaultBinding = [[BookVault BookVaultSoap] retain];
	//vaultBinding.logXMLInOut = YES;
	BookVault_VaultContentsWithToken* vaultContentsRequest = [[BookVault_VaultContentsWithToken new] autorelease];
	vaultContentsRequest.token = self.token; 
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
	}
	
	
}

@end
