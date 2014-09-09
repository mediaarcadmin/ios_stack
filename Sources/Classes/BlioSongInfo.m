//
//  BlioSongInfo.m
//  StackApp
//
//  Created by Arnold Chien on 5/28/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import "BlioSongInfo.h"

@implementation BlioSongInfo

@synthesize artist, trackNumber, downloadAvailable;

-(id)initWithDictionary:(NSDictionary*)productDict {
    if (self = [super initWithDictionary:productDict]) {
        // For now.  Will need [productDict valueForKey:@"Contributor"], I think, but that's always empty at the moment.
        self.artist = @"";
        // For now, dummy value.
        self.trackNumber = 0;
        NSInteger purchaseCount = [[productDict valueForKey:@"PurchaseCount"] integerValue];
        NSInteger downloadsCompleted = [[productDict valueForKey:@"DownloadsCompleted"] integerValue];
        self.downloadAvailable = (downloadsCompleted < purchaseCount)? YES:NO;
    }
    return self;
}

@end
