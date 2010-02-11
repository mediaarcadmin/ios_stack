//
//  BlioStoreEntityController.h
//  BlioApp
//
//  Created by matt on 10/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioStoreFeedBooksParser.h"

@interface BlioStoreEntityController : UITableViewController <BlioStoreFeedBooksParserDelegate> {
    BlioStoreParsedEntity *entity;
    BlioStoreFeedBooksParser *parser;
}

@property (nonatomic, retain) BlioStoreParsedEntity *entity;

@end
