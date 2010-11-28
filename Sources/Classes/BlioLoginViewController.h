//
//  BlioLoginViewController.h
//  BlioApp
//
//  Created by Arnold Chien on 4/6/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioProcessing.h"
#import "BlioStoreManager.h"
#import "DigitalLockerGateway.h"
#import "BlioRoundedRectActivityView.h"

@interface BlioLoginViewController : UITableViewController<UITextFieldDelegate,UITableViewDelegate,UITableViewDataSource,DigitalLockerConnectionDelegate> {
	UITextField* emailField;
	UITextField* passwordField;
	BlioRoundedRectActivityView * activityIndicatorView;
	BlioBookSourceID sourceID;
	UIView * loginFooterView;
}

@property (nonatomic,retain) UITextField* emailField;
@property (nonatomic,retain) UITextField* passwordField;
@property (nonatomic,retain) BlioRoundedRectActivityView* activityIndicatorView;
@property (nonatomic,assign) BlioBookSourceID sourceID;
@property (nonatomic,retain) UIView * loginFooterView;


-(void)receivedLoginResult:(BlioLoginResult)loginResult;
-(id)initWithSourceID:(BlioBookSourceID)bookSourceID;
- (UITextField *)createEmailTextField;
- (UITextField *)createPasswordTextField;
-(void)forgotPassword:(id)sender;
@end
