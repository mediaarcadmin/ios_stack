//
//  BlioWelcomeViewController.h
//  BlioApp
//
//  Created by Don Shin on 12/16/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioProcessing.h"
#import "BlioStoreManager.h"

static const CGFloat kBlioWelcomeCellMargin = 10.0f;

@class BlioWelcomeTableViewCell;

@interface BlioWelcomeTitleView : UIView {
	UILabel * welcomeToLabel;
	UILabel * blioLabel;
}
@end;

@interface BlioWelcomeView : UIView {
	UIImageView * logoView;
	UIView * welcomeTitleView;
	UILabel * welcomeTextView;
	UILabel * existingUserTitleView;
	UILabel * existingUserTextView;
	UIButton * existingUserButton;
	UILabel * firstTimeUserTitleView;
	UILabel * firstTimeUserTextView;
	UIButton * firstTimeUserButton;
	CGFloat contentMargin;
}
@property (nonatomic, readonly) UIButton * firstTimeUserButton;
@property (nonatomic, readonly) UIButton * existingUserButton;

@end

@interface BlioWelcomeViewController : UIViewController <BlioLoginResultReceiver> {
	BlioBookSourceID sourceID;
    UIImageView * logoView;
    BlioWelcomeTitleView * welcomeTitleView;
    UILabel * welcomeTextView;
    UIView * cellContainerView;
    BlioWelcomeTableViewCell * cell1;
    BlioWelcomeTableViewCell * cell2;
    BlioWelcomeTableViewCell * cell3;
}
@property(nonatomic,assign) BlioBookSourceID sourceID;
@property(nonatomic,retain) UIImageView * logoView;
@property(nonatomic,retain) BlioWelcomeTitleView * welcomeTitleView;
@property(nonatomic,retain) UILabel * welcomeTextView;
@property(nonatomic,retain) UIView * cellContainerView;
@property(nonatomic,retain) BlioWelcomeTableViewCell * cell1;
@property(nonatomic,retain) BlioWelcomeTableViewCell * cell2;
@property(nonatomic,retain) BlioWelcomeTableViewCell * cell3;

- (id)initWithSourceID:(BlioBookSourceID)aSourceID;

@end
