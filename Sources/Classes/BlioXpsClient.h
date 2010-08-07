//
//  XpsClient.h
//  PlayReadyTestapp
//
//  Created by Arnold Chien on 5/18/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XpsSdk.h"
#include "zlib.h"

static NSString* const encryptedImageMapDir = @"/Documents/1/Other/KNFB/";
static NSString* const encryptedPagesDir = @"/Documents/1/Other/KNFB/Epages/";
static NSString* const encryptedTextflowDir = @"/Documents/1/Other/KNFB/Flow/";
static NSString* const encryptedImagesDir = @"/Resources/";

@interface BlioXpsClient : NSObject {
	
}

- (id)init;
- (void*)openFile:(NSString*)xpsFile;
- (void)closeFile:(void*)fileHandle;
- (void*)openComponent:(void*)fileHandle componentPath:(NSString*)path;
- (NSInteger)readComponent:(void*)componentHandle componentBuffer:(void*)buffer componentLen:(NSInteger)len;
- (void)closeComponent:(void*)componentHandle;
- (NSInteger)inflateInit:(void*)stream; 
- (int)decompress:(unsigned char*)inBuffer inBufferSz:(NSInteger)sz outBuffer:(unsigned char**)outBuf outBufferSz:(NSInteger*)outBufSz;

@end
