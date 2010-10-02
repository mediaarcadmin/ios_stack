//
//  CCInAppPurchaseService.h
//  BlioApp
//
//  Created by Don Shin on 9/30/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CCInAppPurchaseConnection;
@class CCInAppPurchaseResponse;
static NSString* const CCInAppPurchaseURL = @"http://judah.crosscomm.net:8080/blio-mobile-server/productservice/";
static NSString* const CCInAppPurchaseURLTest = @"http://judah.crosscomm.net:8080/blio-mobile-server/productservice/";

@interface CCInAppPurchaseProduct : NSObject {
	NSString * dateCreated;
	NSString * description;
	NSString * isActive;
	NSString * langCode;
	NSString * lastModified;
	NSString * name;
	NSString * price;
	NSString * productId;
}
@property (nonatomic, retain) NSString * dateCreated;
@property (nonatomic, retain) NSString * description;
@property (nonatomic, retain) NSString * isActive;
@property (nonatomic, retain) NSString * langCode;
@property (nonatomic, retain) NSString * lastModified;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * price;
@property (nonatomic, retain) NSString * productId;

@end

@interface CCInAppPurchaseResponse : NSObject {
	
}

@end

@interface CCInAppPurchaseFetchProductsResponse : CCInAppPurchaseResponse {
	NSMutableArray * products;
}
@property (nonatomic, retain) NSMutableArray * products;

@end
@interface CCInAppPurchasePurchaseProductResponse : CCInAppPurchaseResponse {
}

@end

@interface CCInAppPurchaseRequest : NSObject {

}
@property (nonatomic, readonly) NSURLRequest * URLRequest;
@property (nonatomic, readonly) Class responseClass;

-(CCInAppPurchaseResponse*)responseFromData:(NSData*)data;

@end

@interface CCInAppPurchaseFetchProductsRequest : CCInAppPurchaseRequest<NSXMLParserDelegate> {
	CCInAppPurchaseFetchProductsResponse * _response;
	CCInAppPurchaseProduct * _product;
	NSMutableString * _characterString;
}

@end

@interface CCInAppPurchasePurchaseProductsRequest : CCInAppPurchaseRequest {
	NSString * hardwareId;
	NSString * productId;
}
@property (nonatomic, copy) NSString * hardwareId;
@property (nonatomic, copy) NSString * productId;
@end
@protocol CCInAppPurchaseConnectionDelegate<NSObject>

@required

- (void)connectionDidFinishLoading:(CCInAppPurchaseConnection *)aConnection;

@optional

- (void)connection:(CCInAppPurchaseConnection *)aConnection didFailWithError:(NSError *)error;

@end

@interface CCInAppPurchaseConnection : NSObject {
	id<CCInAppPurchaseConnectionDelegate> delegate;
	CCInAppPurchaseRequest * _request;
	NSMutableData * responseData;
	long expectedContentLength;
	CCInAppPurchaseResponse * inAppPurchaseResponse;
}
@property (nonatomic, assign)id<CCInAppPurchaseConnectionDelegate> delegate;
@property (nonatomic, readonly) CCInAppPurchaseRequest * request;
@property (nonatomic, retain) NSMutableData * responseData;
@property (nonatomic, readonly) long expectedContentLength;
@property (nonatomic, retain) CCInAppPurchaseResponse * inAppPurchaseResponse;

-(id)initWithRequest:(CCInAppPurchaseRequest*)request;
-(void) start;
@end
