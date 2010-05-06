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


@interface BlioBookVaultManager : NSObject {
	BlioLoginManager* loginManager;
	BlioProcessingManager* processingManager;
	NSManagedObjectContext* managedObjectContext;
	NSMutableArray* _isbns; // array of ISBN numbers
}

@property (nonatomic, retain) BlioLoginManager* loginManager;
@property (nonatomic, retain) BlioProcessingManager* processingManager;
@property (nonatomic, retain) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, copy,readonly) NSMutableArray* isbns;

- (ContentCafe_ProductItem*)getContentMetaDataFromISBN:(NSString*)isbn;
- (void)archiveBooks;
- (BOOL)fetchBooksFromServer;
- (NSURL*)URLForPaidBook:(NSString*)isbn;
-(BOOL)hasValidToken;

@end
