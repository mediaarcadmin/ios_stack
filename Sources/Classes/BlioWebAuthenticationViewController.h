//
//  BlioWebAuthenticationViewController.h
//  StackApp
//
//  Created by Arnold Chien on 1/28/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BlioWebAuthenticationViewController : UIViewController/*BlioAutorotatingTableViewController*/ <UIWebViewDelegate, NSURLConnectionDelegate> {
    UIWebView *loginView;
    NSURL* loginURL;
    NSMutableData *_data;
    NSURL *_url;
}

- (id)initWithURL:(NSString *)url;

@end
