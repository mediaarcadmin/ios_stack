//
//  BlioPurchaseVoicesViewController.h
//  BlioApp
//
//  Created by Don Shin on 10/1/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

typedef enum {
	BlioVoiceDownloadButtonStateDownload = 0,
	BlioVoiceDownloadButtonStateInProgress = 1,
	BlioVoiceDownloadButtonStateInstalled = 2
} BlioVoiceDownloadButtonState;

static const CGFloat kBlioVoiceDownloadButtonWidth = 100.0f;
static const CGFloat kBlioVoiceDownloadButtonHeight = 24.0f;
static const CGFloat kBlioVoiceDownloadButtonRightMargin = 10.0f;

static const CGFloat kBlioVoiceDownloadProgressViewWidth = 100.0f;
static const CGFloat kBlioVoiceDownloadProgressViewHeight = 10.0f;
static const CGFloat kBlioVoiceDownloadProgressViewRightMargin = 10.0f;
@interface BlioPurchaseVoicesViewController : UITableViewController <SKProductsRequestDelegate,SKPaymentTransactionObserver> {
	NSArray * availableVoicesForDownload;
}

@property (nonatomic, retain) NSArray * availableVoicesForDownload;

- (void) failedTransaction:(SKPaymentTransaction *)transaction;
- (void) restoreTransaction:(SKPaymentTransaction *)transaction;
- (void) completeTransaction:(SKPaymentTransaction *)transaction;
@end

@interface BlioPurchaseVoiceTableViewCell : UITableViewCell {
	UIButton * downloadButton;
	NSString * voice;
	UIProgressView * progressView;
	UILabel * progressLabel;
}

@property (nonatomic, retain) UIButton * downloadButton;
@property (nonatomic, copy) NSString * voice;
@property (nonatomic, retain) UIProgressView * progressView;
@property (nonatomic, retain) UILabel * progressLabel;

-(void)configureWithVoice:(NSString*)aVoice;
-(void)setDownloadButtonState:(BlioVoiceDownloadButtonState)buttonState;
-(NSString*)progressLabelFormattedText;

@end
