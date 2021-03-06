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
#import "BlioProcessing.h"

@interface BlioStoreFeed : NSObject {
    Class parserClass;
    BlioStoreBooksSourceParser *parser;
	BlioBookSourceID sourceID;
    NSString *title;
    NSMutableArray *categories;
    NSMutableArray *entities;
    NSURL *feedURL;
	NSURL * nextURL;
	NSString * id;
	NSUInteger totalResults;
	NSInteger previousFeedCount;
}

@property (nonatomic, retain) Class parserClass;
@property (nonatomic, retain) BlioStoreBooksSourceParser *parser;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSMutableArray *categories;
@property (nonatomic, retain) NSMutableArray *entities;
@property (nonatomic, retain) NSURL *feedURL;
@property (nonatomic, retain) NSURL *nextURL;
@property (nonatomic, retain) NSString *id;
@property (nonatomic, assign) NSUInteger totalResults;
@property (nonatomic, assign) BlioBookSourceID sourceID;
@property (nonatomic, assign) NSInteger previousFeedCount;

@end
