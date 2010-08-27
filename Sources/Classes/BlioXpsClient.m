//
//  XpsClient.m
//  PlayReadyTestapp
//
//  Created by Arnold Chien on 5/18/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import "BlioXpsClient.h"

#define SHORT_PTR(b,ofs) ((uShort *)&b[ofs])

@implementation BlioXpsClient

- (id)init {
    if ((self = [super init])) {
        XPS_Start();
    }
    return self;
}

- (int)decompress:(unsigned char*)inBuffer inBufferSz:(NSInteger)inBufSz outBuffer:(unsigned char**)outBuf outBufferSz:(NSInteger*)outBufSz {
//- (int)decompress:(unsigned char*)inbuf inbufSz:(NSInteger)sz {
	int ret;
	unsigned bytesDecompressed;
	z_stream strm;
	const int BUFSIZE=16384;
	unsigned char outbuf[BUFSIZE];
	NSMutableData* outData = [[NSMutableData alloc] init];
	
	// Read the gzip header.
	// TESTING
	//unsigned char ID1 = inBuffer[0];  // should be x1f
	//unsigned char ID2 = inBuffer[1];  // should be x8b
	//unsigned char CM = inBuffer[2];   // should be 8
	
	// Allocate inflate state.
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
	strm.opaque = Z_NULL;
	strm.avail_in = 0;
	strm.next_in = Z_NULL;
	
	ret = [self inflateInit:&strm]; 
	
	if (ret != Z_OK) {
		[outData release];
		return ret;
	}
	
	strm.avail_in = inBufSz;
	// if (strm.avail_in == 0)
	//	  break;
	strm.next_in = inBuffer;
	// Inflate until the output buffer isn't full
	do {
		strm.avail_out = BUFSIZE;
		strm.next_out = outbuf;
		ret = XPS_inflate(&strm,Z_NO_FLUSH); 
		// ret should be Z_STREAM_END
		switch (ret) {
			case Z_NEED_DICT:
				ret = Z_DATA_ERROR;
			case Z_DATA_ERROR:
			case Z_MEM_ERROR:
				XPS_inflateEnd(&strm);
				[outData release];
				return ret;
		}
		bytesDecompressed = BUFSIZE - strm.avail_out;
		NSData* data = [[NSData alloc] initWithBytes:(const void*)outbuf length:bytesDecompressed];
		[outData appendData:data];
		[data release];
	}
	while (strm.avail_out == 0);
	XPS_inflateEnd(&strm);
	
	// TESTING
	//NSString* testStr = [[NSString alloc] initWithData:outData encoding:NSASCIIStringEncoding];
	//NSLog(@"Unencrypted buffer: %s",testStr);
	*outBuf = (unsigned char*)malloc([outData length]);  
    [outData getBytes:*outBuf length:[outData length]];
	*outBufSz = [outData length];
	[outData release];
	
	if (ret == Z_STREAM_END)
		return Z_OK;
	return Z_DATA_ERROR;
}

- (void*)openFile:(NSString*)xpsFile {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	return (void*)XPS_Open([xpsFile cStringUsingEncoding:NSASCIIStringEncoding],
						   [documentsDirectory cStringUsingEncoding:NSASCIIStringEncoding]);
}

- (void)closeFile:(void*)fileHandle {
	XPS_Close(fileHandle);
}

- (void*)openComponent:(void*)fileHandle componentPath:(NSString*)path {
	return (void*)XPS_OpenComponent(fileHandle, 
									(char*)[path cStringUsingEncoding:NSASCIIStringEncoding], 
									0); // not writeable
}

- (NSInteger)readComponent:(void*)componentHandle componentBuffer:(void*)buffer componentLen:(NSInteger)len {
	return (NSInteger)XPS_ReadComponent(componentHandle,buffer,(int)len); 
}

- (void)closeComponent:(void*)componentHandle{
	XPS_CloseComponent(componentHandle);
}

- (NSInteger)inflateInit:(void*)stream {
	return (NSInteger)XPS_inflateInit2(stream,31); // second argument = 15 (default window size) + 16 (for gzip decoding)	
}


@end
