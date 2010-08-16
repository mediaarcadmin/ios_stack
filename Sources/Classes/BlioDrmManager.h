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

static const NSInteger BlioDrmManagerInitialLicenseCooldownTime = 10;

@interface BlioDrmManager : NSObject {
	BOOL drmInitialized;
    NSManagedObjectID *headerBookID;
    NSManagedObjectID *boundBookID;
	NSInteger licenseCooldownTime;
	NSTimer * licenseCooldownTimer;
}

@property (nonatomic, assign) BOOL drmInitialized;
@property (nonatomic, assign) NSInteger licenseCooldownTime;
@property (nonatomic, assign) NSTimer * licenseCooldownTimer;

+ (BlioDrmManager*)getDrmManager;
- (void)initialize;
- (void)reportReadingForBookWithID:(NSManagedObjectID *)aBookID;
- (BOOL)getLicenseForBookWithID:(NSManagedObjectID *)aBookID;
- (BOOL)decryptData:(NSData *)data forBookWithID:(NSManagedObjectID *)aBookID;
- (void)startLicenseCooldownTimer;
- (void)resetLicenseCooldownTimer;

@end
