//
//  BlioDrmSessionManager.h
//  BlioApp
//
//  Created by Arnold Chien on 8/25/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioBookManager.h"
#import "KNFBDrmBookDecrypter.h"

static NSString * const BlioDrmFailureAlertType = @"BlioDrmFailureAlertType";

//struct BlioDrmSessionManagerDrmIVars;

@interface BlioDrmSessionManager : NSObject <KNFBDrmBookDecrypter> {
	//BOOL drmInitialized;
    //NSManagedObjectID *headerBookID;
    //NSManagedObjectID *boundBookID;
    //struct BlioDrmSessionManagerDrmIVars *drmIVars;
}

//@property (nonatomic, assign) BOOL drmInitialized;

- (id)initWithBookID:(NSManagedObjectID *)aBookID;
- (BOOL)leaveDomain:(NSString*)token;
- (BOOL)getLicense:(NSString*)token;
//- (BOOL)joinDomain:(NSString*)token domainName:(NSString*)name;
//- (BOOL)joinDomain:(NSString*)token domainName:(NSString*)name alertAlways:(BOOL)alertFlag;

@end

