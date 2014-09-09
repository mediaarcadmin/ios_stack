//
//  BlioMedia.m
//  StackApp
//
//  Created by Arnold Chien on 2/14/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import "BlioMediaInfo.h"

@implementation BlioMediaInfo

@synthesize productID, title, graphic, transactionType, datePurchased, canExpire;

-(id)initWithDictionary:(NSDictionary*)productDict {
    if (self = [super init]) {
        self.productID = [productDict valueForKey:@"ProductId"];
        self.title = [productDict valueForKey:@"Title"];
        self.graphic = [productDict valueForKey:@"Graphic"];
        // Next three are not currently returned in vault details, so set to default values.
        // Are they needed for iOS app?  If so, get from full product details or ask that they be returned in vault details.
        self.datePurchased = nil;
        self.canExpire = 0;
        // Note: transactionType assumed to be sale for now.  In future will read from JSON.
        self.transactionType = BlioTransactionTypeSale;
        // Next two are obsolete for this class.
        //self.expiration = nil;
        // TODO: ?figure out from [productDict valueForKey:@"Contributor"]
        //self.primaryContributor = @"";
    }
    return self;
}


@end
