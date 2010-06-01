//
//  BlioDrmManager.h
//  BlioApp
//
//  Created by Arnold Chien on 5/29/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define HDS_STORE_FILE  L".\\playready.hds"
#define MAX_URL_SIZE	1024

@interface BlioDrmManager : NSObject {
	BOOL drmInitialized;
	unsigned char* xpsHeaderData;
	unsigned int xpsHeaderSize;
}

@property (nonatomic, assign) BOOL drmInitialized;
@property (nonatomic, assign) unsigned char* xpsHeaderData;
@property (nonatomic, assign) unsigned int xpsHeaderSize;

+ (BlioDrmManager*)getDrmManager;

- (void)initialize;

- (void)getLicense;

@end
