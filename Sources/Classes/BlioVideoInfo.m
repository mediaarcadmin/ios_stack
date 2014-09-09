//
//  BlioVideoInfo.m
//  StackApp
//
//  Created by Arnold Chien on 5/28/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import "BlioVideoInfo.h"

@implementation BlioVideoInfo

@synthesize genres, directors, actors, publishers, filePath, duration;

-(id)initWithDictionary:(NSDictionary*)productDict {
    if (self = [super initWithDictionary:productDict]) {
        // For now.
        self.genres = @"";
        self.actors = @"";
        self.directors = @"";
        self.publishers = @"";
        self.filePath = @"";
        self.duration = 0;
    }
    return self;
}

@end
