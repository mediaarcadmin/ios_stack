//
//  DigitalLockerGateway.h
//  BlioApp
//
//  Created by Don Shin on 9/16/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString * const DigitalLockerBlioAppID = @"APPID-OEM-HP-001-";

static NSString * const DigitalLockerGatewayURLTest = @"https://gw.bliodigitallocker.net/nww/gateway/request";
static NSString * const DigitalLockerGatewayURLProduction = @"https://gw.bliodigitallocker.com/nww/gateway/request";

static NSString * const DigitalLockerServiceRegistration = @"Registration";

static NSString * const DigitalLockerMethodCreate = @"Create";
static NSString * const DigitalLockerMethodLogin = @"Login";
static NSString * const DigitalLockerMethodForgot = @"Forgot";

static NSString * const DigitalLockerInputDataFirstNameKey = @"FirstName";
static NSString * const DigitalLockerInputDataLastNameKey = @"LastName";
static NSString * const DigitalLockerInputDataEmailKey = @"UserEmail";
static NSString * const DigitalLockerInputDataPasswordKey = @"UserPassword";
static NSString * const DigitalLockerInputDataEmailOptionKey = @"EmailOption";



@interface DigitalLockerXMLObject : NSObject<NSXMLParserDelegate> {
	NSMutableString * parserCharacters;
	DigitalLockerXMLObject * parent;
}
@property (nonatomic, assign) DigitalLockerXMLObject * parent;

+(NSString*)serializeDictionary:(NSDictionary*)dictionary withName:(NSString*)aName;

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

@interface DigitalLockerResponseOutputData : DigitalLockerXMLObject {
	NSString * OutputDataType;
}
@property (nonatomic, readonly) NSString * OutputDataType;
@end

@interface DigitalLockerResponseOutputDataRegistration : DigitalLockerResponseOutputData {
	NSInteger UserNum;
	NSString * UserName;
	NSString * UserEmail;
	NSString * FirstName;
	NSString * LastName;
	BOOL UserNewAccount;
	BOOL UserAuthenticated;
	NSString * EmailOption;
	NSInteger AccountNum;
	NSInteger BookVaultId;
}
@property (nonatomic, assign) NSInteger UserNum;
@property (nonatomic, retain) NSString * UserName;
@property (nonatomic, retain) NSString * UserEmail;
@property (nonatomic, retain) NSString * FirstName;
@property (nonatomic, retain) NSString * LastName;
@property (nonatomic, assign) BOOL UserNewAccount;
@property (nonatomic, assign) BOOL UserAuthenticated;
@property (nonatomic, retain) NSString * EmailOption;
@property (nonatomic, assign) NSInteger AccountNum;
@property (nonatomic, assign) NSInteger BookVaultId;

@end

@interface DigitalLockerResponse : DigitalLockerXMLObject {
	NSInteger ReturnCode;
	NSString * ReturnMessage;
	NSString * ResponseTime;
	NSMutableArray * Errors;
	
	DigitalLockerResponseOutputData * OutputData;
}
@property (nonatomic, assign) NSInteger ReturnCode;
@property (nonatomic, retain) NSString * ReturnMessage;
@property (nonatomic, retain) NSString * ResponseTime;
@property (nonatomic, retain) NSMutableArray * Errors;
@property (nonatomic, retain) DigitalLockerResponseOutputData * OutputData;

@end

@interface DigitalLockerState : DigitalLockerXMLObject {
	NSString * _ClientIPAddress;
	NSString * _ClientDomain;
	NSString * _ClientLanguage;
	NSString * _ClientLocation;
	NSString * _ClientUserAgent;
	NSString * _SiteKey;
	NSString * _SiteNum;
	NSString * _AppID;	
}

+(NSString *) SessionId;

@property (nonatomic, readonly) NSString * ClientIPAddress;
@property (nonatomic, readonly) NSString * ClientDomain;
@property (nonatomic, readonly) NSString * ClientLanguage;
@property (nonatomic, readonly) NSString * ClientLocation;
@property (nonatomic, readonly) NSString * ClientUserAgent;
@property (nonatomic, retain) NSString * SiteKey;
@property (nonatomic, retain) NSString * SiteNum;
@property (nonatomic, readonly) NSString * AppID;

@end

@interface DigitalLockerRequest : DigitalLockerXMLObject {
	NSString * Service;
	NSString * Method;
	NSMutableDictionary * InputData;
}

@property (nonatomic, retain) NSString * Service;
@property (nonatomic, retain) NSString * Method;
@property (nonatomic, retain) NSMutableDictionary * InputData;

@end

@class DigitalLockerConnection;

@protocol DigitalLockerConnectionDelegate<NSObject>

@required

- (void)connectionDidFinishLoading:(DigitalLockerConnection *)aConnection;

@optional

- (void)connection:(DigitalLockerConnection *)aConnection didFailWithError:(NSError *)error;

@end

@interface DigitalLockerConnection : DigitalLockerXMLObject {
	DigitalLockerRequest * _Request;
	DigitalLockerState * _State;
	id<DigitalLockerConnectionDelegate> _delegate;
	NSURLConnection * urlConnection;
	NSMutableData * _responseData;
	DigitalLockerResponse * digitalLockerResponse;
	NSString * _gatewayURL;
	NSMutableArray * parserDelegateStack;
}
-(id)initWithDigitalLockerRequest:(DigitalLockerRequest*)aRequest delegate:(id)delegate;
-(id)initWithDigitalLockerRequest:(DigitalLockerRequest*)aRequest siteNum:(NSInteger)aNum siteKey:(NSString*)aKey delegate:(id)delegate;
-(void)start;

@property (nonatomic, retain) DigitalLockerRequest * Request;
@property (nonatomic, readonly) DigitalLockerState * State;
@property (nonatomic, assign) id<DigitalLockerConnectionDelegate> delegate;
@property (nonatomic, retain) NSURLConnection * urlConnection;
@property (nonatomic, retain) DigitalLockerResponse * digitalLockerResponse;
@property (nonatomic, retain) NSMutableArray * parserDelegateStack;

@end

