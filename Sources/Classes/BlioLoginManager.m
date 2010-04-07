//
//  BlioLoginManager.m
//  BlioApp
//
//  Created by Arnold Chien on 4/5/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import "BlioLoginManager.h"
#import "BlioBookVault.h"

@implementation BlioLoginManager

@synthesize timeout, username, token, isLoggedIn;

- (BlioLoginResult)login:(NSString*)user password:(NSString*)passwd {
	BookVaultSoap *vaultBinding = [[BookVault BookVaultSoap] retain];
	vaultBinding.logXMLInOut = YES;
	BookVault_Login *loginRequest = [[BookVault_Login new] autorelease];
	loginRequest.username = user;	//@"gordonfrog@gmail.com" account for testing
	loginRequest.password = passwd; //@"Gumby01";  
	loginRequest.siteId =  [NSNumber numberWithInt:12151];		// hard-coded in Windows Blio
	BookVaultSoapResponse * response = [vaultBinding LoginUsingParameters:loginRequest];
	
	NSArray *responseBodyParts = response.bodyParts;
	for(id bodyPart in responseBodyParts) {
		if ([bodyPart isKindOfClass:[SOAPFault class]]) {
			NSString* err = ((SOAPFault *)bodyPart).simpleFaultString;
			NSLog(@"SOAP error: %s",err);
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


@end
