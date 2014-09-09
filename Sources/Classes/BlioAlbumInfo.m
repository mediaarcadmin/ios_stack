//
//  BlioAlbumInfo.m
//  StackApp
//
//  Created by Arnold Chien on 5/28/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import "BlioAlbumInfo.h"

@implementation BlioAlbumInfo

@synthesize artist;

-(id)initWithDictionary:(NSDictionary*)productDict {
    if (self = [super initWithDictionary:productDict]) {
        // For now.  Will need [productDict valueForKey:@"Contributor"], I think, but that's always empty at the moment.
        self.artist = @"";
    }
    return self;
}

@end
