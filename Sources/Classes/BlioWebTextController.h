//
//  BlioPrivacyTextControllerViewController.h
//  BlioApp
//
//  Created by Arnold Chien on 8/7/12.
//  Copyright (c) 2012 Kurzweil Technologies Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioAutorotatingViewController.h"

@interface BlioWebTextController : BlioAutorotatingViewController <UIWebViewDelegate>
    @property (nonatomic, retain) UIWebView *contentView;
    @property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
    - (id)initWithURL:(NSString*)url;
@end
