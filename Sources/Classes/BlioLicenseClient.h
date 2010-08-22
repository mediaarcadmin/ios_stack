//
//  BlioLicenseClient.h
//  BlioApp
//
//  Created by Arnold Chien on 6/3/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum  {
	BlioSoapActionAcquireLicense = 0,
    BlioSoapActionJoinDomain,
    BlioSoapActionLeaveDomain,
} BlioSoapActionType;

@interface BlioLicenseClient : NSObject {
	NSMutableURLRequest* request;
}

@property (nonatomic, retain) NSMutableURLRequest* request;

- (id)initWithMessage:(const void*)msg messageSize:(NSUInteger)msgSize url:(NSString*)url soapAction:(BlioSoapActionType)action;
- (NSData *)getResponseSynchronously;

@end
