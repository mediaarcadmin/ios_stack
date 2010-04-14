//
//  BlioLoginViewController.h
//  BlioApp
//
//  Created by Arnold Chien on 4/6/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioLoginManager.h"
#import "BlioBookVaultManager.h"

@interface BlioLoginViewController : UIViewController<UITextFieldDelegate,UITableViewDelegate,UITableViewDataSource> {
	UITableView	*loginTableView;
	BlioBookVaultManager* vaultManager;
	UITextField* usernameField;
	UITextField* passwordField;
	UILabel* statusField;
	UIActivityIndicatorView* activityIndicator;
}

@property (nonatomic,retain) BlioBookVaultManager* vaultManager;
@property (nonatomic,retain) UITableView* loginTableView;
@property (nonatomic,retain) UITextField* usernameField;
@property (nonatomic,retain) UITextField* passwordField;
@property (nonatomic,retain) UILabel* statusField;
@property (nonatomic,retain) UIActivityIndicatorView* activityIndicator;

@end
