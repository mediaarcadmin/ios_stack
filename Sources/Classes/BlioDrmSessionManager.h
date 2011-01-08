//
//  BlioDrmSessionManager.h
//  BlioApp
//
//  Created by Arnold Chien on 8/25/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


#import <Foundation/Foundation.h>
#import "BlioBookManager.h"

#define HDS_STORE_FILE  L".\\playready.hds"
#define MAX_URL_SIZE	1024

//static const NSInteger BlioDrmManagerInitialLicenseCooldownTime = 10;
static NSString * const BlioDrmReportReadingFailureAlertType = @"BlioDrmReportReadingFailureAlertType";

struct BlioDrmSessionManagerDrmIVars; 

@interface BlioDrmSessionManager : NSObject {
	BOOL drmInitialized;
    NSManagedObjectID *headerBookID;
    NSManagedObjectID *boundBookID;
    struct BlioDrmSessionManagerDrmIVars *drmIVars;
}

@property (nonatomic, assign) BOOL drmInitialized;

- (id)initWithBookID:(NSManagedObjectID *)aBookID;
- (BOOL)joinDomain:(NSString*)token domainName:(NSString*)name;
- (BOOL)leaveDomain:(NSString*)token;
- (BOOL)reportReading;
- (BOOL)getLicense:(NSString*)token;
- (BOOL)bindToLicense;
- (BOOL)decryptData:(NSData *)data;

@end

