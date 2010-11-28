//
//  BlioOnlineStoreHelper.h
//  BlioApp
//
//  Created by Arnold Chien and Don Shin on 4/5/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioStoreHelper.h"
#import "BlioContentCafe.h"
#import "BlioBookVault.h"
#import "DigitalLockerGateway.h"

static NSString * const BlioIOSStoreSiteKey = @"B870B960A5B4CB53363BB10855FDC3512658E69E";

@class BlioOnlineStoreHelper;

@interface BlioOnlineStoreHelperBookVaultDelegate : NSObject <BookVaultSoapResponseDelegate> {
	BlioOnlineStoreHelper * delegate;
}
@property (assign) BlioOnlineStoreHelper * delegate;

@end

@interface BlioOnlineStoreHelperContentCafeDelegate : NSObject <ContentCafeSoapResponseDelegate> {
	BlioOnlineStoreHelper * delegate;
}
@property (assign) BlioOnlineStoreHelper * delegate;

@end

@interface BlioOnlineStoreHelper : BlioStoreHelper <DigitalLockerConnectionDelegate> {
	NSMutableArray* _isbns; // array of ISBN numbers
	NSInteger newISBNs;
	NSInteger responseCount;
	NSInteger successfulResponseCount;
	BlioOnlineStoreHelperBookVaultDelegate * bookVaultDelegate;
	BlioOnlineStoreHelperContentCafeDelegate * contentCafeDelegate;
}

@end
