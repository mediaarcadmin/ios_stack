//
//  BlioInAppPurchaseManager.m
//  BlioApp
//
//  Created by Don Shin on 8/23/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import "BlioInAppPurchaseManager.h"


@implementation BlioInAppPurchaseManager

-(void)requestProductsWithProductIdentifiers:(NSSet*)aSet {
	SKProductsRequest* productRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:aSet];	
	productRequest.delegate = self;
	[productRequest start];
}
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
	NSArray* productObjects = response.products;
	NSLog(@"received %i products from apple product request",[productObjects count]);
}	
@end
