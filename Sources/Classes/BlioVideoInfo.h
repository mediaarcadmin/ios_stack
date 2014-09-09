//
//  BlioVideoInfo.h
//  StackApp
//
//  Created by Arnold Chien on 5/28/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import "BlioMediaInfo.h"

@interface BlioVideoInfo : BlioMediaInfo

@property (nonatomic, retain) NSString* genres;
@property (nonatomic, retain) NSString* directors;
@property (nonatomic, retain) NSString* actors;
@property (nonatomic, retain) NSString* publishers;
@property (nonatomic, retain) NSString* filePath;
@property (nonatomic, assign) double duration;

@end
