//
//  BlioStoreCategoriesController.h
//  BlioApp
//
//  Created by matt on 05/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioStoreFeedBooksParser.h"

static const NSInteger kBlioStoreCategoriesTag = 1;

@interface BlioStoreCollectionController : UITableViewController <BlioStoreFeedBooksParserDelegate> {
    NSMutableArray *categories;
    NSMutableArray *entities;
    BlioStoreFeedBooksParser *parser;
    NSURL *feedURL;
}

@property (nonatomic, retain) NSURL *feedURL;

@end
