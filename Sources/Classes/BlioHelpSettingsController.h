//
//  BlioHelpSettingsController.h
//  BlioApp
//
//  Created by Arnold Chien on 7/30/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioAutorotatingViewController.h"

@interface BlioHelpSettingsController : BlioAutorotatingTableViewController <UIWebViewDelegate> {
	UIWebView *textView;
}

@end
