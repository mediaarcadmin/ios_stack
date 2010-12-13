//
//  BlioInAppPurchaseManager.h
//  BlioApp
//
//  Created by Don Shin on 8/23/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "CCInAppPurchaseService.h"

static NSString * const BlioInAppPurchaseProductsFetchStarted = @"BlioInAppPurchaseProductsFetchStarted";
static NSString * const BlioInAppPurchaseProductsFetchFailed = @"BlioInAppPurchaseProductsFetchFailed";
static NSString * const BlioInAppPurchaseProductsFetchFinished = @"BlioInAppPurchaseProductsFetchFinished";
static NSString * const BlioInAppPurchaseProductsUpdated = @"BlioInAppPurchaseProductsUpdated";
static NSString * const BlioInAppPurchaseTransactionFailed = @"BlioInAppPurchaseTransactionFailed";
static NSString * const BlioInAppPurchaseTransactionRestored = @"BlioInAppPurchaseTransactionRestored";
static NSString * const BlioInAppPurchaseTransactionPurchased = @"BlioInAppPurchaseTransactionPurchased";

static NSString * const BlioInAppPurchaseNotificationTransactionKey = @"BlioInAppPurchaseNotificationTransactionKey";

@interface BlioInAppPurchaseVoice : NSObject {
	NSString * dateCreated;
	NSString * description;
	NSString * isActive;
	NSString * langCode;
	NSString * lastModified;
	NSString * name;
	NSString * price;
	NSString * productId;
}

@end

@interface BlioInAppPurchaseManager : NSObject<CCInAppPurchaseConnectionDelegate,SKProductsRequestDelegate,SKPaymentTransactionObserver> {
	NSMutableArray * inAppProducts;
	BOOL isFetchingProducts;
}
@property (nonatomic, retain) NSMutableArray * inAppProducts;
@property (nonatomic, assign) BOOL isFetchingProducts;
+(BlioInAppPurchaseManager*)sharedInAppPurchaseManager;
- (BOOL)canMakePurchases;
-(void)purchaseProductWithID:(NSString*)anID;
-(BOOL)isPurchasingProductWithID:(NSString*)anID;
-(void)fetchProductsFromProductServer;
- (void) failedTransaction:(SKPaymentTransaction *)transaction;
- (void) restoreTransaction:(SKPaymentTransaction *)transaction;
- (void) completeTransaction:(SKPaymentTransaction *)transaction;
- (BOOL)verifyReceipt:(SKPaymentTransaction *)transaction;
- (NSString *)encode:(const uint8_t *)input length:(NSInteger)length;
@end
