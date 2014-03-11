//
//  BlioMyAccountViewController.h
//  BlioApp
//
//  Created by Don Shin on 10/15/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioDrmSessionManager.h"
#import "BlioAppSettingsController.h"
#import "BlioAutorotatingViewController.h"

@interface BlioMyAccountViewController : BlioAutorotatingTableViewController<NSURLSessionDataDelegate> {
    BOOL registrationOn;
	BlioDrmSessionManager* drmSessionManager;
    UITableViewCell *deregisterCell;
    UITableViewCell *supportTokenCell;
    id delegate;
    NSMutableData* supportTokenData;
    UIActivityIndicatorView* cellActivityIndicatorView;
}
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, assign) BOOL registrationOn;
@property (nonatomic, retain) BlioDrmSessionManager* drmSessionManager;
@property (nonatomic, assign) id delegate;
@end
