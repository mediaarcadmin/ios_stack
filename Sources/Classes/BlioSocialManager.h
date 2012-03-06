//
//  BlioSocialManager.h
//  BlioApp
//
//  Created by Don Shin on 2/29/12.
//  Copyright (c) 2012 CrossComm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>
#import "BlioBook.h"
#import "Facebook.h"

typedef enum {
    BlioSocialTypeFacebook = 0,
    BlioSocialTypeTwitter = 1,
} BlioSocialType;

@interface BlioSocialManager : NSObject<FBSessionDelegate,FBDialogDelegate> {
    UIViewController * rootViewController;
    Facebook * _facebook;
    BlioBook * _bookToBeShared;
}

@property(nonatomic,retain) UIViewController * rootViewController;

+(BlioSocialManager*)sharedSocialManager;
+(BOOL)canSendTweet;
-(void)shareBook:(BlioBook*)aBook socialType:(BlioSocialType)socialType;

@end
