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

@interface BlioOnlineStoreHelper : BlioStoreHelper<BookVaultSoapResponseDelegate> {
	NSMutableArray* _isbns; // array of ISBN numbers
}
- (ContentCafe_ProductItem*)getContentMetaDataFromISBN:(NSString*)isbn;
- (BOOL)fetchBookISBNArrayFromServer;
@end
