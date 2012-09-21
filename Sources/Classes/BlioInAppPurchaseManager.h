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

static NSString * const BlioInAppPurchaseProductsFetchStartedNotification = @"BlioInAppPurchaseProductsFetchStartedNotification";
static NSString * const BlioInAppPurchaseProductsFetchFailedNotification = @"BlioInAppPurchaseProductsFetchFailedNotification";
static NSString * const BlioInAppPurchaseProductsFetchFinishedNotification = @"BlioInAppPurchaseProductsFetchFinishedNotification";
static NSString * const BlioInAppPurchaseProductsUpdatedNotification = @"BlioInAppPurchaseProductsUpdatedNotification";
static NSString * const BlioInAppPurchaseTransactionFailedNotification = @"BlioInAppPurchaseTransactionFailedNotification";
static NSString * const BlioInAppPurchaseTransactionRestoredNotification = @"BlioInAppPurchaseTransactionRestoredNotification";
static NSString * const BlioInAppPurchaseTransactionPurchasedNotification = @"BlioInAppPurchaseTransactionPurchasedNotification";
static NSString * const BlioInAppPurchaseRestoreTransactionsStartedNotification = @"BlioInAppPurchaseRestoreTransactionsStartedNotification";
static NSString * const BlioInAppPurchaseRestoreTransactionsFailedNotification = @"BlioInAppPurchaseRestoreTransactionsFailedNotification";
static NSString * const BlioInAppPurchaseRestoreTransactionsFinishedNotification = @"BlioInAppPurchaseRestoreTransactionsFinishedNotification";

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
	BOOL isRestoringTransactions;
}
@property (nonatomic, retain) NSMutableArray * inAppProducts;
@property (nonatomic, readonly) BOOL isFetchingProducts;
@property (nonatomic, readonly) BOOL isRestoringTransactions;
+(BlioInAppPurchaseManager*)sharedInAppPurchaseManager;
- (BOOL)canMakePurchases;
-(void)restoreProductWithID:(NSString*)anID;
-(void)purchaseProductWithID:(NSString*)anID;
-(BOOL)isPurchasingProductWithID:(NSString*)anID;
-(BOOL)hasPreviouslyPurchasedProductWithID:(NSString*)anID;
-(void)fetchProductsFromProductServer;
- (BOOL)verifyReceipt:(SKPaymentTransaction *)transaction;
-(void)restoreCompletedTransactions;
@end
