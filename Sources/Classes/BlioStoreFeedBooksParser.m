//
//  BlioStoreFeedBooksParser.m
//  BlioApp
//
//  Created by matt on 09/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioStoreFeedBooksParser.h"

//static NSUInteger kBlioStoreFeedBooksParserCountForNotification = 10;

@implementation BlioStoreFeedBooksParser

@synthesize parsedCategories, parsedEntities;

- (void)dealloc {
    self.parsedCategories = nil;
    self.parsedEntities = nil;
    [super dealloc];
}

- (void)start {
    self.parsedCategories = [NSMutableArray array];
    self.parsedEntities = [NSMutableArray array];
    //NSURL *url = [NSURL URLWithString:@"http://ax.phobos.apple.com.edgesuite.net/WebObjects/MZStore.woa/wpa/MRSS/newreleases/limit=300/rss.xml"];
    //[NSThread detachNewThreadSelector:@selector(downloadAndParse:) toTarget:self withObject:url];
}


@end
