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
#import "BlioAutorotatingViewController.h"

typedef enum {
	BlioVoiceDownloadButtonStatePurchase = 0,
	BlioVoiceDownloadButtonStatePurchasing = 1,
	BlioVoiceDownloadButtonStateInProgress = 2,
	BlioVoiceDownloadButtonStateInstalled = 3,
    BlioVoiceDownloadButtonStatePreviouslyPurchased = 4
} BlioVoiceDownloadButtonState;

static const CGFloat kBlioVoiceDownloadButtonWidth = 100.0f;
static const CGFloat kBlioVoiceDownloadButtonHeight = 24.0f;
static const CGFloat kBlioVoiceDownloadButtonRightMargin = 10.0f;

static const CGFloat kBlioVoiceDownloadProgressViewWidth = 100.0f;
static const CGFloat kBlioVoiceDownloadProgressViewHeight = 10.0f;
static const CGFloat kBlioVoiceDownloadProgressViewRightMargin = 10.0f;

@protocol BlioPurchaseVoiceViewDelegate

-(void)purchaseProductWithID:(NSString*)productID;
-(void)restoreProductWithID:(NSString*)productID;

@end


@interface BlioPurchaseVoicesViewController : BlioAutorotatingTableViewController <BlioPurchaseVoiceViewDelegate> {
	NSMutableArray * availableVoicesForPurchase;
	BlioRoundedRectActivityView * activityIndicatorView;
    BOOL autoDownloadPreviousPurchases;
}

@property (nonatomic, retain) NSMutableArray * availableVoicesForPurchase;
@property (nonatomic,retain) BlioRoundedRectActivityView* activityIndicatorView;
@property (nonatomic,assign) BOOL autoDownloadPreviousPurchases;

@end

@interface BlioPurchaseVoiceTableViewCell : UITableViewCell {
	UIButton * downloadButton;
	CCInAppPurchaseProduct * product;
	UIProgressView * progressView;
	UILabel * progressLabel;
	BlioVoiceDownloadButtonState buttonState;
	id<BlioPurchaseVoiceViewDelegate> delegate;
}

@property (nonatomic, retain) UIButton * downloadButton;
@property (nonatomic, retain) CCInAppPurchaseProduct * product;
@property (nonatomic, retain) UIProgressView * progressView;
@property (nonatomic, retain) UILabel * progressLabel;
@property (nonatomic, assign) id<BlioPurchaseVoiceViewDelegate> delegate;

-(void)configureWithInAppPurchaseProduct:(CCInAppPurchaseProduct*)aProduct;
-(void)setDownloadButtonState:(BlioVoiceDownloadButtonState)buttonState;
-(NSString*)progressLabelFormattedText;
@end
