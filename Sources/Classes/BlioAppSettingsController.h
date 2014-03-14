//
//  BlioAppSettingsController.h
//  BlioApp
//
//  Created by Arnold Chien on 2/20/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioAutorotatingViewController.h"

@interface BlioAppSettingsController : BlioAutorotatingTableViewController {
    BOOL didDeregister;
    UIActivityIndicatorView* loginActivityIndicatorView;
}
@property (nonatomic, assign) BOOL didDeregister;
//-(void)attemptLogin;

@end
