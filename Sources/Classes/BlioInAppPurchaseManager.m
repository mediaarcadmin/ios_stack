//
//  BlioInAppPurchaseManager.m
//  BlioApp
//
//  Created by Don Shin on 8/23/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import "BlioInAppPurchaseManager.h"
#import "CCInAppPurchaseService.h"

@implementation BlioInAppPurchaseVoice

@end

@implementation BlioInAppPurchaseManager

@synthesize products;

+(BlioInAppPurchaseManager*)sharedInAppPurchaseManager
{
	static BlioInAppPurchaseManager * sharedInAppPurchaseManager = nil;
	if (sharedInAppPurchaseManager == nil) {
		sharedInAppPurchaseManager = [[BlioInAppPurchaseManager alloc] init];
	}
	
	return sharedInAppPurchaseManager;
}
-(void)dealloc {
	self.products = nil;
	[super dealloc];
}
-(void)fetchProductsFromProductServer {
	CCInAppPurchaseConnection * connection = [[CCInAppPurchaseConnection alloc] initWithRequest:[[[CCInAppPurchaseFetchProductsRequest alloc] init] autorelease]];
	connection.delegate = self;
	[connection start];
}
-(void)requestProductsWithProductIdentifiers:(NSSet*)aSet {
	SKProductsRequest* productRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:aSet];	
	productRequest.delegate = self;
	[productRequest start];
}
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
	self.products = response.products;
	NSLog(@"received %i products from apple product request",[self.products count]);

	// broadcast notification
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioInAppPurchaseProductsUpdated object:self];
}	
- (void)requestDidFinish:(SKRequest *)request {
	[request release];
}
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
	// TODO:flesh this out
}
- (void)connectionDidFinishLoading:(CCInAppPurchaseConnection *)aConnection {
	if ([aConnection.inAppPurchaseResponse isKindOfClass:[CCInAppPurchaseFetchProductsResponse class]]) {
		CCInAppPurchaseFetchProductsResponse * fetchProductsResponse = (CCInAppPurchaseFetchProductsResponse*)aConnection.inAppPurchaseResponse;
		NSMutableArray * productIDs = [NSMutableArray array];
		for (CCInAppPurchaseProduct * product in fetchProductsResponse.products) {
			NSLog(@"product: %@",product);
			[productIDs addObject:product.productId];
		}
		[self requestProductsWithProductIdentifiers:[NSSet setWithArray:productIDs]];		
	}
	else if ([aConnection.inAppPurchaseResponse isKindOfClass:[CCInAppPurchasePurchaseProductResponse class]]) {
		
	}
}
- (void)connection:(CCInAppPurchaseConnection *)aConnection didFailWithError:(NSError *)error {
	if ([aConnection.request isKindOfClass:[CCInAppPurchaseFetchProductsRequest class]]) {
		
	}
	else if ([aConnection.request isKindOfClass:[CCInAppPurchaseFetchProductsRequest class]]) {
		
	}
}
@end
