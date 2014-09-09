//
//  BlioMedia.h
//  StackApp
//
//  Created by Arnold Chien on 2/14/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioProcessing.h"

@interface BlioMedia : NSObject {
    
}

@property (nonatomic, retain) NSString* productID;
@property (nonatomic, retain) NSString* title;
@property (nonatomic, retain) NSString* primaryContributor;
@property (nonatomic, retain) NSString* graphic;
@property (nonatomic, assign) BlioTransactionType transactionType;
@property (nonatomic, retain) NSDate* datePurchased;
@property (nonatomic, retain) NSDate* expiration;

-(id)initWithDictionary:(NSDictionary*)productDict;

@end