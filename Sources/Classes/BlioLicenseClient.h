//
//  BlioLicenseClient.h
//  BlioApp
//
//  Created by Arnold Chien on 6/3/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlioLicenseClient : NSObject {
	NSURLConnection* connection;
	NSMutableURLRequest* request;
	long expectedContentLength;   
}

@property (nonatomic, retain) NSURLConnection* connection;
@property (nonatomic, retain) NSMutableURLRequest* request;
@property (nonatomic, assign) long expectedContentLength;

-(id)initWithMessage:(const void*)msg messageSize:(NSUInteger)msgSize;
-(BOOL)getResponse:(unsigned char**)resp responseSize:(unsigned int*)respSize;

@end
