//
//  BlioMyAccountViewController.h
//  BlioApp
//
//  Created by Don Shin on 10/15/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioDrmSessionManager.h"

@interface BlioMyAccountViewController : UITableViewController {
    UIActivityIndicatorView *activityIndicator;
	BOOL registrationOn;
	BlioDrmSessionManager* drmSessionManager;
    UISwitch * registrationSwitch;
}
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, assign) BOOL registrationOn;
@property (nonatomic, retain) BlioDrmSessionManager* drmSessionManager;
@end
