//
//  BlioVoiceOverTextController.h
//  BlioApp
//
//  Created by Don Shin on 10/6/11.
//  Copyright (c) 2011 CrossComm, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioAutorotatingViewController.h"

@interface BlioVoiceOverTextController : BlioAutorotatingViewController <UIWebViewDelegate> {
UIWebView *textView;
}
@end
