//
//  BlioPaidBooksSettingsController.h
//  BlioApp
//
//  Created by Arnold Chien on 7/7/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioDrmSessionManager.h"

@interface BlioPaidBooksSettingsController : UITableViewController <UITableViewDelegate, UITableViewDataSource> {
	UITableView *pbTableView;
	UIActivityIndicatorView *activityIndicator;
	BOOL registrationOn;
	BlioDrmSessionManager* drmSessionManager;
}

@property (nonatomic, retain) UITableView *pbTableView;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, assign) BOOL registrationOn;
@property (nonatomic, retain) BlioDrmSessionManager* drmSessionManager;

@end
