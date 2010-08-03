//
//  BlioAboutSettingsController.h
//  BlioApp
//
//  Created by Arnold Chien on 7/30/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BlioAboutSettingsController : UITableViewController <UITableViewDelegate, UITableViewDataSource> {
	UITableView *aboutTableView;
}

@property (nonatomic, retain) UITableView *aboutTableView;

@end
