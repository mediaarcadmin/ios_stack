//
//  BlioAlbumInfo.h
//  StackApp
//
//  Created by Arnold Chien on 5/28/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioMediaInfo.h"

@interface BlioAlbumInfo : BlioMediaInfo

@property (nonatomic, retain) NSString* artist;

-(id)initWithDictionary:(NSDictionary*)productDict;

@end
