//
//  BlioLoginView.m
//  BlioApp
//
//  Created by Arnold Chien on 4/1/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import "BlioLoginView.h"
#import "BlioBookVault.h"

@interface UIAlertView (extended)
- (UITextField *) textFieldAtIndex: (int) index;
- (void) addTextFieldWithValue: (NSString *) value label: (NSString *) label;
@end

@implementation BlioLoginView

- (void)display {
	
	[self addTextFieldWithValue:@"" label:@"Enter username"];
	[self addTextFieldWithValue:@"" label:@"Enter password"];
	
	UITextField *tf = [self textFieldAtIndex:0];
	tf.clearButtonMode = UITextFieldViewModeWhileEditing;
	tf.keyboardType = UIKeyboardTypeAlphabet;
	tf.keyboardAppearance = UIKeyboardAppearanceAlert;
	tf.autocapitalizationType = UITextAutocapitalizationTypeWords;
	tf.autocorrectionType = UITextAutocorrectionTypeNo;
	
	tf = [self textFieldAtIndex:1];
	tf.clearButtonMode = UITextFieldViewModeWhileEditing;
	tf.keyboardType = UIKeyboardTypeURL;
	tf.keyboardAppearance = UIKeyboardAppearanceAlert;
	tf.autocapitalizationType = UITextAutocapitalizationTypeNone;
	tf.autocorrectionType = UITextAutocorrectionTypeNo;
	
	[self show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

	if ( buttonIndex != 1 )
		return;
	BookVaultSoap *vaultBinding = [[BookVault BookVaultSoap] retain];
	//vaultBinding.logXMLInOut = YES;
	BookVault_Login *loginRequest = [[BookVault_Login new] autorelease];
	loginRequest.username = @"gordonfrog@gmail.com"; //  account for testing
	loginRequest.password = @"Gumby01";  
	loginRequest.siteId =  [NSNumber numberWithInt:12151]; // hard-coded in Windows Blio
	BookVaultSoapResponse * response = [vaultBinding LoginUsingParameters:loginRequest];

	NSArray *responseHeaders = response.headers;
	NSArray *responseBodyParts = response.bodyParts;
	for(id header in responseHeaders) {
		;
	}

	for(id bodyPart in responseBodyParts) {
		if ([bodyPart isKindOfClass:[SOAPFault class]]) {
			NSString* err = ((SOAPFault *)bodyPart).simpleFaultString;
			NSLog(@"SOAP error: %s",err);
			continue;
		}
	}


/*
 BookVaultSoap *binding = [BookVault BookVaultSoap];
 binding.logXMLInOut = YES;
 BookVaultSoap_Login *request = [[BookVaultSoap_Login new] autorelease];
 request.attribute = @"attributeValue";
 request.element = [[ns1_MyElement new] autorelease];
 request.element.value = @"elementValue"];
 
 BookVaultSoapResponse *response = [binding LoginUsingParameters:request];
 
 NSArray *responseHeaders = response.headers;
 NSArray *responseBodyParts = response.bodyParts;
 
 
 for(id header in responseHeaders) {
 if([header isKindOfClass:[ns2_MyHeaderResponse class]]) {
 ns2_MyHeaderResponse *headerResponse = (ns2_MyHeaderResponse*)header;
 
 // ... Handle ns2_MyHeaderResponse ...
 }
 }
 
 for(id bodyPart in responseBodyParts) {
 if([bodyPart isKindOfClass:[ns2_MyBodyResponse class]]) {
 ns2_MyBodyResponse *body = (ns2_MyBodyResponse*)bodyPart;
 
 // ... Handle ns2_MyBodyResponse ...
 }
 }
 */
}

@end
