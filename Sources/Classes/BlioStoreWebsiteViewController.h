//
//  BlioStoreWebsiteViewController.h
//  BlioApp
//
//  Created by Arnold Chien on 4/8/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

static const NSInteger kBlioStoreBuyBooksTag = 5;

@interface BlioStoreWebsitePhoneContentView : UIView
{
	UIView * screenshotView;
	UILabel * headerLabel;
	UILabel * subHeaderLabel;
}
@property (nonatomic, retain) UIView * screenshotView;
@property (nonatomic, retain) UILabel * headerLabel;
@property (nonatomic, retain) UILabel * subHeaderLabel;

@end


@interface BlioStoreWebsiteViewController : UIViewController {
	//UIButton* launchButton;
	//UIButton* createAccountButton;
	UILabel * explanationLabel;
	BlioStoreWebsitePhoneContentView * phoneContentView;
}
@property (nonatomic, retain) UILabel * explanationLabel;
@property (nonatomic, retain) BlioStoreWebsitePhoneContentView * phoneContentView;
//-(void)updateLogin;
-(void)updateExplanation;
- (void)launchWebsite:(id)sender;
@end