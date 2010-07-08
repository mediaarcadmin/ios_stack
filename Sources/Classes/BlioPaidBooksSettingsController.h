//
//  BlioPaidBooksSettingsController.h
//  BlioApp
//
//  Created by Arnold Chien on 7/7/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BlioPaidBooksSettingsController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	UITableView *pbTableView;
}

@property (nonatomic, retain) UITableView *pbTableView;

@end
