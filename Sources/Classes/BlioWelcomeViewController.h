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
	BlioWelcomeView * welcomeView;
	BlioBookSourceID sourceID;
}
@property(nonatomic,readonly) BlioWelcomeView * welcomeView;
@property(nonatomic,assign) BlioBookSourceID sourceID;

- (id)initWithSourceID:(BlioBookSourceID)aSourceID;

@end
