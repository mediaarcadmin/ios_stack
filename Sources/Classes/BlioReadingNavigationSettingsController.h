//
//  BlioTapZoomSettingsController.h
//  BlioApp
//
//  Created by Arnold Chien on 10/23/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BlioReadingNavigationSettingsController : UITableViewController <UITableViewDelegate, UITableViewDataSource> {
	UITableView *pbTableView;
	BOOL tapToZoomOn;
}

@property (nonatomic, retain) UITableView *pbTableView;

@end
