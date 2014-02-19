//
//  BlioCloudMedia.h
//  StackApp
//
//  Created by Arnold Chien on 2/14/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioMedia.h"

@interface BlioCloudMedia : BlioMedia

@property (nonatomic, retain) NSURL* graphic;
@property (nonatomic, retain) NSDate* transactionType;
@property (nonatomic, retain) NSDate* loanExpiration;

@end
