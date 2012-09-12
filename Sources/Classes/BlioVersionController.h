//
//  BlioVersionController.h
//  BlioApp
//
//  Created by Arnold Chien on 8/2/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioAutorotatingViewController.h"

@interface BlioVersionController : BlioAutorotatingTableViewController <UIWebViewDelegate> {
	UIWebView *textView;
}

@end
