//
//  DigitalLockerGateway.h
//  BlioApp
//
//  Created by Don Shin on 9/16/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString * const DigitalLockerGatewayURLTest = @"https://gw.bliodigitallocker.net/nww/gateway/request";
static NSString * const DigitalLockerGatewayURLProduction = @"https://gw.bliodigitallocker.com/nww/gateway/request";

@interface DigitalLockerXMLObject : NSObject<NSXMLParserDelegate> {
	NSMutableString * parserCharacters;
	DigitalLockerXMLObject * parent;
}
@property (nonatomic, assign) DigitalLockerXMLObject * parent;

@end

@interface DigitalLockerResponseError : DigitalLockerXMLObject {
	NSInteger ErrorCode;
	NSString * ErrorType;
	NSString * ErrorText;
	NSString * ErrorField;
	NSString * ErrorValue;
}
@property (nonatomic, assign) NSInteger ErrorCode;
@property (nonatomic, retain) NSString * ErrorType;
@property (nonatomic, retain) NSString * ErrorText;
@property (nonatomic, retain) NSString * ErrorField;
@property (nonatomic, retain) NSString * ErrorValue;

@end

@interface DigitalLockerResponse : DigitalLockerXMLObject {
	NSInteger ReturnCode;
	NSString * ReturnMessage;
	NSString * ResponseTime;
	NSMutableArray * Errors;
	//	DigitalLockerResponseOutputData * OutputData;
}
@property (nonatomic, assign) NSInteger ReturnCode;
@property (nonatomic, retain) NSString * ReturnMessage;
@property (nonatomic, retain) NSString * ResponseTime;
@property (nonatomic, retain) NSMutableArray * Errors;

@end

@interface DigitalLockerRequest : DigitalLockerXMLObject {
	NSString * xmlString;
}

@property (nonatomic, copy) NSString * xmlString;

@end

@class DigitalLockerConnection;

@protocol DigitalLockerConnectionDelegate<NSObject>

@required

- (void)connectionDidFinishLoading:(DigitalLockerConnection *)aConnection;

@optional

- (void)connection:(DigitalLockerConnection *)aConnection didFailWithError:(NSError *)error;

@end

@interface DigitalLockerConnection : DigitalLockerXMLObject {
	DigitalLockerRequest * _request;
	id<DigitalLockerConnectionDelegate> _delegate;
	NSURLConnection * urlConnection;
	NSMutableData * _responseData;
	DigitalLockerResponse * digitalLockerResponse;
	NSString * _gatewayURL;
	NSMutableArray * parserDelegateStack;
}
-(id)initWithDigitalLockerRequest:(DigitalLockerRequest*)request delegate:(id)delegate;
-(void)start;

@property (nonatomic, retain) DigitalLockerRequest * request;
@property (nonatomic, assign) id<DigitalLockerConnectionDelegate> delegate;
@property (nonatomic, retain) NSURLConnection * urlConnection;
@property (nonatomic, retain) DigitalLockerResponse * digitalLockerResponse;
@property (nonatomic, retain) NSMutableArray * parserDelegateStack;

@end

