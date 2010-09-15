//
//  BlioCreateAccountViewController.h
//  BlioApp
//
//  Created by Don Shin on 9/12/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioLoginViewController.h"

static NSString * const BlioPasswordInvalidCharacters = @"&\"<>'";
static const NSUInteger BlioPasswordCharacterLengthMinimum = 8;

@interface BlioCreateAccountViewController : BlioLoginViewController {
	UITextField* confirmPasswordField;
	NSMutableData * createAccountResponseData;

}
@property (nonatomic,retain) UITextField* confirmPasswordField;
@property (nonatomic,retain) NSMutableData * createAccountResponseData;

@end
