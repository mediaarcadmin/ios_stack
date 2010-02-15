//
//  BlioStoreFeed.m
//  BlioApp
//
//  Created by matt on 15/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioStoreFeed.h"


@implementation BlioStoreFeed

@synthesize parserClass, parser, title, categories, entities, feedURL;

- (id)init {
    if ((self = [super init])) {
        self.categories = [NSMutableArray array];
        self.entities = [NSMutableArray array];
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
    [super dealloc];
}

@end
