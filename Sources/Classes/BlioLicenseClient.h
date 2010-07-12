//
//  BlioLicenseClient.h
//  BlioApp
//
//  Created by Arnold Chien on 6/3/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlioLicenseClient : NSObject {
	NSMutableURLRequest* request;
}

@property (nonatomic, retain) NSMutableURLRequest* request;

- (id)initWithMessage:(const void*)msg messageSize:(NSUInteger)msgSize;
- (NSData *)getResponseSynchronously;

@end
