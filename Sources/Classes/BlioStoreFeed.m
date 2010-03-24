//
//  BlioStoreFeed.m
//  BlioApp
//
//  Created by matt on 15/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioStoreFeed.h"


@implementation BlioStoreFeed

@synthesize parserClass, parser, title, categories, entities, feedURL, nextURL, totalResults, id;

- (id)init {
    if ((self = [super init])) {
        self.categories = [NSMutableArray array];
        self.entities = [NSMutableArray array];
		totalResults = 0;
		self.nextURL = nil;
		self.id = nil;
    }
    return self;
}

- (void)dealloc {
    self.parserClass = nil;
    [self.parser setDelegate:nil]; // Required to stop background parsing trheads messaging this controller
    self.parser = nil;
    self.title = nil;
    self.categories = nil;
    self.entities = nil;
    self.feedURL = nil;
    self.nextURL = nil;
    [super dealloc];
}

@end
