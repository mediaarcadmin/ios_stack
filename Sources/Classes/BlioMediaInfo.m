//
//  BlioMedia.m
//  StackApp
//
//  Created by Arnold Chien on 2/14/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import "BlioMedia.h"

@implementation BlioMedia

@synthesize productID, title, primaryContributor, graphic, transactionType, datePurchased, expiration;

-(id)initWithDictionary:(NSDictionary*)productDict {
    if (self = [super init]) {
        self.productID = [productDict valueForKey:@"ProductId"];
        self.title = [productDict valueForKey:@"Title"];
        self.graphic = [productDict valueForKey:@"Graphic"];
        // Next two not currently returned in product list.
        self.expiration = nil;
        self.datePurchased = nil;
        // TODO: figure out from [productDict valueForKey:@"Contributor"]
        self.primaryContributor = @"";
        // Note: transactionType assumed to be sale for now.  In future will read from JSON.
        self.transactionType = BlioTransactionTypeSale;
    }
    return self;
}


@end
