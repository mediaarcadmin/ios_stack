//
//  BlioStoreFeed.h
//  BlioApp
//
//  Created by matt on 15/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioStoreBooksSourceParser.h"
#import "BlioStoreLocalParser.h"
#import "BlioStoreFeedBooksParser.h"
#import "BlioStoreGoogleBooksParser.h"

@interface BlioStoreFeed : NSObject {
    Class parserClass;
    BlioStoreBooksSourceParser *parser;
    NSString *title;
    NSMutableArray *categories;
    NSMutableArray *entities;
    NSURL *feedURL;
}

@property (nonatomic) Class parserClass;
@property (nonatomic, retain) BlioStoreBooksSourceParser *parser;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSMutableArray *categories;
@property (nonatomic, retain) NSMutableArray *entities;
@property (nonatomic, retain) NSURL *feedURL;

@end
