//
//  BlioDrmManager.h
//  BlioApp
//
//  Created by Arnold Chien on 5/29/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioBookManager.h"

#define HDS_STORE_FILE  L".\\playready.hds"
#define MAX_URL_SIZE	1024

@interface BlioDrmManager : NSObject {
	BOOL drmInitialized;
    NSManagedObjectID *bookID;
}

@property (nonatomic, assign) BOOL drmInitialized;

+ (BlioDrmManager*)getDrmManager;
- (void)initialize;
- (BOOL)getLicenseForBookWithID:(NSManagedObjectID *)aBookID;
- (BOOL)decryptData:(NSData *)data forBookWithID:(NSManagedObjectID *)aBookID;

@end
