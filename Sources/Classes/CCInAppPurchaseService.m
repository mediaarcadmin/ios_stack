//
//  CCInAppPurchaseService.m
//  BlioApp
//
//  Created by Don Shin on 9/30/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import "CCInAppPurchaseService.h"

@implementation CCInAppPurchaseProduct 

@synthesize dateCreated,description,isActive,langCode,lastModified,name,price,productId;
-(void)dealloc {
	self.dateCreated = nil;
	self.description = nil;
	self.isActive = nil;
	self.langCode = nil;
	self.lastModified = nil;
	self.name = nil;
	self.price = nil;
	self.productId = nil;
	[super dealloc];
}
@end

@implementation CCInAppPurchaseResponse 

@end

@implementation CCInAppPurchaseFetchProductsResponse
@synthesize products;

-(id)init {
	if((self = [super init])) {
		self.products = [NSMutableArray array];
	}
	return self;
}

-(void)dealloc {
	self.products = nil;
	[super dealloc];

}
@end
@implementation CCInAppPurchasePurchaseProductResponse

@end

@implementation CCInAppPurchaseRequest 

@synthesize	responseClass;

-(NSURLRequest*)URLRequest {
	return[[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:CCInAppPurchaseURL]] autorelease];
}
-(CCInAppPurchaseResponse*)responseFromData:(NSData*)data {
	return nil;
}
@end

@implementation CCInAppPurchaseFetchProductsRequest

-(CCInAppPurchaseResponse*)responseFromData:(NSData*)data {
	_response = [[CCInAppPurchaseFetchProductsResponse alloc] init];
	NSXMLParser * responseParser = [[NSXMLParser alloc] initWithData:data];
	[responseParser setDelegate:self];
	[responseParser parse];
	CCInAppPurchaseResponse* returnResponse = _response;
	_response = nil;
	[responseParser release];
	return [returnResponse autorelease];
}
#pragma mark -
#pragma mark NSXMLParserDelegate methods
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	if ( [elementName isEqualToString:@"product"] ) {
		_product = [[CCInAppPurchaseProduct alloc] init];
	}
}
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	if (!_characterString) {
        _characterString = [[NSMutableString alloc] initWithCapacity:50];
    }
    [_characterString appendString:string];
	
}
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	if ( [elementName isEqualToString:@"product"] ) {
		[_response.products addObject:_product];
		[_product release];
		_product = nil;
	}
	else if ( [elementName isEqualToString:@"dateCreated"] ) {
		_product.dateCreated = _characterString;
    }
	else if ( [elementName isEqualToString:@"description"] ) {
		_product.description = _characterString;
    }	
	else if ( [elementName isEqualToString:@"isActive"] ) {
		_product.isActive = _characterString;
    }	
	else if ( [elementName isEqualToString:@"langCode"] ) {
		_product.langCode = _characterString;
    }	
	else if ( [elementName isEqualToString:@"lastModified"] ) {
		_product.lastModified = _characterString;
    }	
	else if ( [elementName isEqualToString:@"name"] ) {
		_product.name = _characterString;
    }	
	else if ( [elementName isEqualToString:@"price"] ) {
		_product.price = _characterString;
    }	
	else if ( [elementName isEqualToString:@"productId"] ) {
		_product.productId = _characterString;
    }	
	if (_characterString) {
        [_characterString release];
        _characterString = nil;
    }	
}

//<product>
//<dateCreated>2010-08-12T11:00:13-04:00</dateCreated>
//<description>Heather's voice</description>
//<isActive>true</isActive>
//<langCode>
//<code>eng</code>
//<lang>English</lang>
//</langCode>
//<lastModified>2010-08-12T11:00:13-04:00</lastModified>
//<name>Heather</name>
//<price>9.99</price>
//<productId>heather</productId>
//</product>
@end

@implementation CCInAppPurchasePurchaseProductsRequest 

@synthesize productId,hardwareId;

-(id)initWithProductID:(NSString*)aProductId hardwareID:(NSString*)aHardwareId {
	if((self = [super init])) {
		self.productId = aProductId;
		self.hardwareId = aHardwareId;
	}
	return self;
}
-(void) dealloc {
	self.productId = nil;
	self.hardwareId = nil;
	[super dealloc];
}
-(NSURLRequest*)URLRequest {
	if (hardwareId && productId) {
		NSString * parameteredURL = [NSString stringWithFormat:@"%@purchase?hardwareId=%@&productId=%@",CCInAppPurchaseURL,hardwareId,productId];
		NSMutableURLRequest * urlRequest = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:parameteredURL]] autorelease];
		[urlRequest setHTTPMethod:@"POST"];
		return urlRequest;
	}
	return nil;
}
@end

@implementation CCInAppPurchaseConnection

@synthesize expectedContentLength,inAppPurchaseResponse,responseData,delegate;
	
-(id)initWithRequest:(CCInAppPurchaseRequest*)aRequest {
	if (!aRequest) return nil;
	if((self = [super init])) {
		_request = [aRequest retain];
	}
	return self;
}
-(void)dealloc {
	if (_request) [_request release];
	self.inAppPurchaseResponse = nil;
	self.responseData = nil;
	[super dealloc];
}
-(void) start{
	NSURLConnection * connection = [[NSURLConnection alloc] initWithRequest:_request.URLRequest delegate:self startImmediately:NO];
	[connection start];
}
-(CCInAppPurchaseRequest*)request {
	return _request;
}
- (void)connection:(NSURLConnection *)theConnection didReceiveResponse:(NSURLResponse *)response {
	if ([response expectedContentLength] != NSURLResponseUnknownLength) expectedContentLength = [response expectedContentLength];
}	
- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)data {
	if (!self.responseData) self.responseData = [NSMutableData data];
	[self.responseData appendData:data];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
	self.inAppPurchaseResponse = [_request responseFromData:self.responseData];
//	else NSLog(@"ERROR: CCInAppPurchaseRequest object does not know the class of its response!");
	[self.delegate connectionDidFinishLoading:self];
}
- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error {
	[self.delegate connection:self didFailWithError:error];
}
@end
