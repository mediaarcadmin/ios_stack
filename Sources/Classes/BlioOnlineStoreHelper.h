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
#import "BlioProcessing.h"

static NSString * const BlioIOSStoreSiteKey = @"B870B960A5B4CB53363BB10855FDC3512658E69E";

@class BlioOnlineStoreHelper;

@interface BlioOnlineStoreHelper : BlioStoreHelper<NSURLSessionDataDelegate> {
    NSMutableData* _data;
    NSURLSession* _session;
    NSMutableDictionary* _books;
	NSInteger newMedia;
	NSInteger bookResponseCount;
	NSInteger responseCount;
	NSInteger successfulResponseCount;
}


@property (nonatomic, retain) NSMutableArray* songInfoArray;
@property (nonatomic, retain) NSMutableArray* videoInfoArray;
@property (nonatomic, retain) NSMutableArray* bookInfoArray;

+(BlioTransactionType)transactionTypeForCode:(NSString*)code;
@end
