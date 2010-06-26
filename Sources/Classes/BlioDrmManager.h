//
//  BlioDrmManager.h
//  BlioApp
//
//  Created by Arnold Chien on 5/29/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioXpsClient.h"

#define HDS_STORE_FILE  L".\\playready.hds"
#define MAX_URL_SIZE	1024

@interface BlioDrmManager : NSObject {
	BOOL drmInitialized;
	void* bookHandle;
	BOOL bookChanged;
	BlioXpsClient* xpsClient;
}

@property (nonatomic, assign) BOOL drmInitialized;
@property (nonatomic, assign) BOOL bookChanged;
@property (nonatomic, assign) void* bookHandle;
@property (nonatomic, retain) BlioXpsClient* xpsClient;

+ (BlioDrmManager*)getDrmManager;

- (void)initialize;

- (void)setBook:(void*)xpsHandle;

- (BOOL)getLicense;

- (BOOL)decryptComponent:(NSString*)component decryptedBuffer:(unsigned char**)decrBuff decryptedBufferSz:(NSInteger*)decrBuffSz;

//- (BOOL)getLicenseForBookPath:(NSString*)xpsPath;

//- (BOOL)decryptComponentInBook:(NSString*)component xpsFileHandle:(void*)fileHandle decryptedBuffer:(unsigned char**)decrBuff decryptedBufferSz:(NSInteger*)decrBuffSz;

@end
