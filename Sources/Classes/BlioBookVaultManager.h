//
//  BlioBookVaultManager.h
//  BlioApp
//
//  Created by Arnold Chien on 4/13/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioLoginManager.h"
#import "BlioProcessingManager.h"

@class ContentCafe_ProductItem;

static NSString * const kBlioOnlineStoreSourceID = @"kBlioOnlineStoreSourceID";

@interface BlioBookVaultManager : NSObject {
	BlioLoginManager* loginManager;
	BlioProcessingManager* processingManager;
	NSMutableArray* _isbns; // array of ISBN numbers
}

@property (nonatomic, retain) BlioLoginManager* loginManager;
@property (nonatomic, retain) BlioProcessingManager* processingManager;
@property (nonatomic, copy,readonly) NSMutableArray* isbns;

- (ContentCafe_ProductItem*)getContentMetaDataFromISBN:(NSString*)isbn;
- (void)archiveBooks;
- (BOOL)fetchBooksFromServer;
- (void)downloadBook:(NSString*)isbn;

@end
