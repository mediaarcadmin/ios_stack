//
//  BlioCreateAccountViewController.h
//  BlioApp
//
//  Created by Don Shin on 9/12/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioLoginViewController.h"
#import "DigitalLockerGateway.h"
#import "BlioStoreManager.h"

static NSString * const BlioPasswordInvalidCharacters = @"&\"<>'";
static const NSUInteger BlioPasswordCharacterLengthMinimum = 6;

@interface BlioCreateAccountViewController : BlioLoginViewController <DigitalLockerConnectionDelegate,BlioLoginResultReceiver> {
	UITextField* confirmPasswordField;
	UITextField* firstNameField;
	UITextField* lastNameField;

}
@property (nonatomic,retain) UITextField* confirmPasswordField;
@property (nonatomic,retain) UITextField* firstNameField;
@property (nonatomic,retain) UITextField* lastNameField;

@end
