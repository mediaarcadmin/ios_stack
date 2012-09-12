//
//  BlioVOTipsSettingsController.h
//  BlioApp
//
//  Created by Arnold Chien on 9/19/11.
//  Copyright (c) 2011 Kurzweil Technologies Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioAutorotatingViewController.h"

@interface BlioVOTipsSettingsController : BlioAutorotatingTableViewController <UIWebViewDelegate> {
	UIWebView *textView;
}

@end