//
//  BlioMedia.h
//  StackApp
//
//  Created by Arnold Chien on 2/14/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioProcessing.h"

@interface BlioMediaInfo : NSObject {
    
}

@property (nonatomic, retain) NSString* productID;
@property (nonatomic, retain) NSString* title;
@property (nonatomic, retain) NSString* graphic;
@property (nonatomic, assign) BlioTransactionType transactionType;
@property (nonatomic, retain) NSDate* datePurchased;
@property (nonatomic, assign) NSInteger canExpire;
//@property (nonatomic, retain) NSDate* expiration;
//@property (nonatomic, retain) NSString* primaryContributor;

-(id)initWithDictionary:(NSDictionary*)productDict;

@end