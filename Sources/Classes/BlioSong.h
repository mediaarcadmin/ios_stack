//
//  BlioSong.h
//  StackApp
//
//  Created by Arnold Chien on 6/5/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BlioMedia.h"

static NSString * const BlioSongKey = @"path";
static NSString * const BlioSongCoverKey = @"coverPath";
static NSString * const BlioSongCoversDictionaryKey = @"resizedCovers";

@interface BlioSong : BlioMedia

// Core data attribute-backed dynamic properties
@property (nonatomic, retain) NSString * artist;
@property (nonatomic, retain) NSNumber * length;
@property (nonatomic, retain) NSNumber * isDownloadable;
@property (nonatomic, retain) NSNumber * downloads;

@property (nonatomic, retain) NSString *coverURL;
@property (nonatomic, retain) NSString *path;
@property (nonatomic, retain) NSString *coverPath;
@property (nonatomic, retain) NSMutableDictionary* resizedCovers;

- (NSData*)coverData;
- (NSData*)pixelSpecificCoverDataForKey:(NSString*)key;

@end
