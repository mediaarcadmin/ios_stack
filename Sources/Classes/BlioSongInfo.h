//
//  BlioSongInfo.h
//  StackApp
//
//  Created by Arnold Chien on 5/28/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import "BlioMediaInfo.h"

@interface BlioSongInfo : BlioMediaInfo

@property (nonatomic, assign) BOOL downloadAvailable;
@property (nonatomic, assign) NSInteger trackNumber;
@property (nonatomic, retain) NSString* artist;

-(id)initWithDictionary:(NSDictionary*)productDict;

@end
