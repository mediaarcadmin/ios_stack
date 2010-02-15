//
//  BlioStoreCategoriesController.h
//  BlioApp
//
//  Created by matt on 05/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioStoreFeed.h"

static const NSInteger kBlioStoreCategoriesTag = 1;

@interface BlioStoreCategoriesController : UITableViewController <BlioStoreBooksSourceParserDelegate> {
    NSMutableArray *feeds;
}

@property (nonatomic, retain) NSMutableArray *feeds;

@end
