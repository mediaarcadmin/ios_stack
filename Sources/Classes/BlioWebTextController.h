//
//  BlioPrivacyTextControllerViewController.h
//  BlioApp
//
//  Created by Arnold Chien on 8/7/12.
//  Copyright (c) 2012 Kurzweil Technologies Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BlioWebTextController : UIViewController<UIWebViewDelegate>
    @property (nonatomic, retain) UIWebView *contentView;
    @property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
    - (id)initWithURL:(NSString*)url;
@end
