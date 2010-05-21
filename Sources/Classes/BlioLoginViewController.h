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

@interface BlioLoginViewController : UITableViewController<UITextFieldDelegate,UITableViewDelegate,UITableViewDataSource> {
	UITextField* usernameField;
	UITextField* passwordField;
	UILabel* statusField;
	UIActivityIndicatorView* activityIndicator;
	BlioBookSourceID sourceID;
}

@property (nonatomic,retain) UITextField* usernameField;
@property (nonatomic,retain) UITextField* passwordField;
@property (nonatomic,retain) UILabel* statusField;
@property (nonatomic,retain) UIActivityIndicatorView* activityIndicator;
@property (nonatomic,assign) BlioBookSourceID sourceID;


-(void)receivedLoginResult:(BlioLoginResult)loginResult;
-(id)initWithSourceID:(BlioBookSourceID)bookSourceID;

@end
