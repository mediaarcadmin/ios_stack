//
//  BlioWebAuthenticationViewController.h
//  StackApp
//
//  Created by Arnold Chien on 1/28/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioLoginService.h"

@interface BlioWebAuthenticationViewController : UIViewController <UIWebViewDelegate, NSURLConnectionDelegate> {
    UIWebView *loginView;
    NSURL* loginURL;
    NSMutableData * checkinData;
    NSMutableData *_data;
    NSURL *_url;
    UIActivityIndicatorView* activityIndicatorView;
    BOOL intentionalPageAbort;
}

- (id)initWithURL:(NSString *)url;

@end
