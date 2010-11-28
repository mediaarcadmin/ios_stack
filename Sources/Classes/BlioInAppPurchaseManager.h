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

static NSString* const BlioInAppPurchaseProductsUpdated = @"BlioInAppPurchaseProductsUpdated";

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

@interface BlioInAppPurchaseManager : NSObject<CCInAppPurchaseConnectionDelegate,SKProductsRequestDelegate> {
	NSArray * products;
}
@property (nonatomic, retain) NSArray * products;

+(BlioInAppPurchaseManager*)sharedInAppPurchaseManager;
-(void)fetchProductsFromProductServer;

@end
