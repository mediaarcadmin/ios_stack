//
//  BlioLoginView.m
//  BlioApp
//
//  Created by Arnold Chien on 4/1/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import "BlioLoginView.h"
#import "BlioLoginManager.h"

@interface UIAlertView (extended)
- (UITextField *) textFieldAtIndex: (int) index;
- (void) addTextFieldWithValue: (NSString *) value label: (NSString *) label;
@end

@implementation BlioLoginView

@synthesize loginManager;

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
	tf.secureTextEntry = YES;
	
	[self show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if ( buttonIndex != 1 )
		return;
	[loginManager login:[[self textFieldAtIndex:0] text] password:[[self textFieldAtIndex:1] text]];

}

@end
