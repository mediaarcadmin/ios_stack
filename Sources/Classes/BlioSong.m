//
//  BlioSong.m
//  StackApp
//
//  Created by Arnold Chien on 6/5/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import "BlioSong.h"


@implementation BlioSong

@dynamic artist;
@dynamic length;
@dynamic isDownloadable;
@dynamic downloads;

@dynamic coverURL;
@dynamic coverPath;
@dynamic path;
@dynamic resizedCovers;

- (NSData*)coverData {
    NSString* coverPath = [self valueForKey:BlioSongCoverKey];
    if (coverPath) {
        NSData* imageData = [self dataFromFileSystemAtPath:coverPath];
        return imageData;
    }
    else
        NSLog(@"Could not retrieve song cover path.");
    return nil;
}

- (NSData*)pixelSpecificCoverDataForKey:(NSString*)key {
    NSMutableDictionary* dict = [self valueForKey:BlioSongCoversDictionaryKey];
    if (dict) {
        NSString* coverPath = [dict valueForKey:key];
        if (coverPath) {
            NSData* imageData = [self dataFromFileSystemAtPath:coverPath];
            return imageData;
        }
        else
            NSLog(@"Could not retrieve path for pixel-specific cover from song covers dictionary.");
    }
    else
        NSLog(@"Could not retrieve song covers dictionary.");
    return nil;
}

@end
