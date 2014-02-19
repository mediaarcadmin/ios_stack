//
//  BlioMedia.h
//  StackApp
//
//  Created by Arnold Chien on 2/14/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlioMedia : NSObject {
    
}

@property (nonatomic, retain) NSString* uuid;
@property (nonatomic, retain) NSString* title;
@property (nonatomic, retain) NSString* primaryContributor;
@property (nonatomic, retain) NSString* mediaLookupID;
@property (nonatomic, retain) NSString* genre;
@property (nonatomic, retain) NSDate* datePurchased;

@end
