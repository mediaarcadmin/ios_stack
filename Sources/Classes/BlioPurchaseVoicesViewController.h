//
//  BlioPurchaseVoicesViewController.h
//  BlioApp
//
//  Created by Don Shin on 10/1/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
#import "CCInAppPurchaseService.h"
#import "BlioRoundedRectActivityView.h"

typedef enum {
	BlioVoiceDownloadButtonStatePurchase = 0,
	BlioVoiceDownloadButtonStatePurchasing = 1,
	BlioVoiceDownloadButtonStateInProgress = 2,
	BlioVoiceDownloadButtonStateInstalled = 3
} BlioVoiceDownloadButtonState;

static const CGFloat kBlioVoiceDownloadButtonWidth = 100.0f;
static const CGFloat kBlioVoiceDownloadButtonHeight = 24.0f;
static const CGFloat kBlioVoiceDownloadButtonRightMargin = 10.0f;

static const CGFloat kBlioVoiceDownloadProgressViewWidth = 100.0f;
static const CGFloat kBlioVoiceDownloadProgressViewHeight = 10.0f;
static const CGFloat kBlioVoiceDownloadProgressViewRightMargin = 10.0f;

@interface BlioPurchaseVoicesViewController : UITableViewController {
	NSMutableArray * availableVoicesForPurchase;
	BlioRoundedRectActivityView * activityIndicatorView;
}

@property (nonatomic, retain) NSMutableArray * availableVoicesForPurchase;
@property (nonatomic,retain) BlioRoundedRectActivityView* activityIndicatorView;

@end

@interface BlioPurchaseVoiceTableViewCell : UITableViewCell {
	UIButton * downloadButton;
	CCInAppPurchaseProduct * product;
	UIProgressView * progressView;
	UILabel * progressLabel;
	BlioVoiceDownloadButtonState buttonState;
}

@property (nonatomic, retain) UIButton * downloadButton;
@property (nonatomic, retain) CCInAppPurchaseProduct * product;
@property (nonatomic, retain) UIProgressView * progressView;
@property (nonatomic, retain) UILabel * progressLabel;

-(void)configureWithInAppPurchaseProduct:(CCInAppPurchaseProduct*)aProduct;
-(void)setDownloadButtonState:(BlioVoiceDownloadButtonState)buttonState;
-(NSString*)progressLabelFormattedText;

@end
