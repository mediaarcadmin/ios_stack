//
//  DigitalLockerGateway.m
//  BlioApp
//
//  Created by Don Shin on 9/16/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#include <ifaddrs.h>
#include <arpa/inet.h>

#import "DigitalLockerGateway.h"

@implementation DigitalLockerXMLObject

@synthesize parent;

-(void)dealloc {
	if (parserCharacters) [parserCharacters release];
	self.parent = nil;
	[super dealloc];
}
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	//	NSLog(@"found characters: %@",string);
	if (!parserCharacters) parserCharacters = [[NSMutableString alloc] initWithCapacity:50];
	[parserCharacters appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {    
	if (parserCharacters) {
		[parserCharacters release];
		parserCharacters = nil;
	}
	parser.delegate = self.parent;
}

@end


@implementation DigitalLockerResponseError

@synthesize ErrorCode, ErrorType, ErrorText, ErrorField, ErrorValue;

-(void)dealloc {
	self.ErrorType = nil;
	self.ErrorText = nil;
	self.ErrorField = nil;
	self.ErrorValue = nil;
	[super dealloc];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {    
	//	NSLog(@"didEndElement: %@",elementName);
	if ( [elementName isEqualToString:@"ErrorCode"] ) {
		if (parserCharacters) {
			self.ErrorCode = [parserCharacters intValue];
			[parserCharacters release];
			parserCharacters = nil;
		}
	}
	else if ( [elementName isEqualToString:@"ErrorType"] ) {
		if (parserCharacters) {
			self.ErrorType = parserCharacters;
			[parserCharacters release];
			parserCharacters = nil;
		}
	}
	else if ( [elementName isEqualToString:@"ErrorText"] ) {
		if (parserCharacters) {
			self.ErrorText = parserCharacters;
			[parserCharacters release];
			parserCharacters = nil;
		}
	}
	else if ( [elementName isEqualToString:@"ErrorField"] ) {
		if (parserCharacters) {
			self.ErrorField = parserCharacters;
			[parserCharacters release];
			parserCharacters = nil;
		}
	}
	else if ( [elementName isEqualToString:@"ErrorValue"] ) {
		if (parserCharacters) {
			self.ErrorValue = parserCharacters;
			[parserCharacters release];
			parserCharacters = nil;
		}
	}
	else if ( [elementName isEqualToString:@"Error"] ){ // we're assuming there will never be a Error node inside a Error node.
		[super parser:parser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
	}
}

@end

@implementation DigitalLockerResponse

@synthesize ReturnCode, ReturnMessage, ResponseTime, Errors;

-(void)dealloc {
	self.ReturnMessage = nil;
	self.ResponseTime = nil;
	self.Errors = nil;
	[super dealloc];
}
#pragma mark -
#pragma mark NSXMLParserDelegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	//	NSLog(@"didStartElement: %@",elementName);
	if ( [elementName isEqualToString:@"Errors"] ) {
		self.Errors = [NSMutableArray array];
	}
	else if ( [elementName isEqualToString:@"Error"] ) {
		DigitalLockerResponseError * error = [[DigitalLockerResponseError alloc] init];
		error.parent = self;
		[self.Errors addObject:error];
		[error release];
		parser.delegate = error;
	}
}
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	//	NSLog(@"found characters: %@",string);
	if (!parserCharacters) parserCharacters = [[NSMutableString alloc] initWithCapacity:50];
	[parserCharacters appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {    
	//	NSLog(@"didEndElement: %@",elementName);
	if ( [elementName isEqualToString:@"ReturnCode"] ) {
		if (parserCharacters) {
			self.ReturnCode = [parserCharacters intValue];
			[parserCharacters release];
			parserCharacters = nil;
		}
	}
	else if ( [elementName isEqualToString:@"ReturnMessage"] ) {
		if (parserCharacters) {
			self.ReturnMessage = parserCharacters;
			[parserCharacters release];
			parserCharacters = nil;
		}
	}
	else if ( [elementName isEqualToString:@"ResponseTime"] ) {
		if (parserCharacters) {
			self.ResponseTime = parserCharacters;
			[parserCharacters release];
			parserCharacters = nil;
		}
	}
	else if ( [elementName isEqualToString:@"Response"] ){ // we're assuming there will never be a Response node inside a Response node.
		[super parser:parser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
	}
}

@end

@implementation DigitalLockerRequest
@synthesize xmlString;
-(void) dealloc {
	self.xmlString = nil;
	[super dealloc];
}
- (NSString *)getIPAddress
{
	NSString *address = @"error";
	struct ifaddrs *interfaces = NULL;
	struct ifaddrs *temp_addr = NULL;
	int success = 0;
	
	// retrieve the current interfaces - returns 0 on success
	success = getifaddrs(&interfaces);
	if (success == 0)
	{
		// Loop through linked list of interfaces
		temp_addr = interfaces;
		while(temp_addr != NULL)
		{
			if(temp_addr->ifa_addr->sa_family == AF_INET)
			{
				// Check if interface is en0 which is the wifi connection on the iPhone
				if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
				{
					// Get NSString from C String
					address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
				}
			}
			
			temp_addr = temp_addr->ifa_next;
		}
	}
	
	// Free memory
	freeifaddrs(interfaces);
	
	return address;
}
@end

@implementation DigitalLockerConnection

@synthesize request = _request;
@synthesize delegate = _delegate;
@synthesize digitalLockerResponse,urlConnection,parserDelegateStack;

-(id)initWithDigitalLockerRequest:(DigitalLockerRequest*)request delegate:(id)delegate {
	if (!request) return nil;
	self = [super init];
	if (self)
	{
		self.request = request;
		self.delegate = delegate;
#ifdef TEST_MODE
		_gatewayURL = DigitalLockerGatewayURLTest;
#else	
		_gatewayURL = DigitalLockerGatewayURLProduction;
#endif
		
		
		//		CFStringRef urlString = CFURLCreateStringByAddingPercentEscapes(
		//																		NULL,
		//																		(CFStringRef)post,
		//																		NULL,
		//																		(CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
		//																		kCFStringEncodingNonLossyASCII );
		//		post = [(NSString *)urlString autorelease];
		
		NSData *postData = [[self.request xmlString] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
		NSString *postLength = [NSString stringWithFormat:@"%d",[postData length]];
		NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init];
		[urlRequest setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://gw.bliodigitallocker.net/nww/gateway/request"]]];
		[urlRequest setHTTPMethod:@"POST"];
		//		[request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
		[urlRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
		//		[request setValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];  
		//		[request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];  
		[urlRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
		[urlRequest setHTTPBody:postData];
		
		_responseData = [[NSMutableData alloc] init];
		
		urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
		self.parserDelegateStack = [NSMutableArray array];
	}
	
	return self;	
}

-(void)start {
	if (self.urlConnection) [self.urlConnection start];
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	self.request = nil;
	self.delegate = nil;
	self.urlConnection = nil;
	if (_responseData) [_responseData release];
	self.digitalLockerResponse = nil;
	self.parserDelegateStack = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark NSURLConnectionDelegate methods

- (void)connection:(NSURLConnection *)theConnection didReceiveResponse:(NSURLResponse *)response {
	NSLog(@"DigitalLockerConnection didReceiveResponse: %@",[[response URL] absoluteString]);
	NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *) response;
	NSLog(@"MIMEType: %@",response.MIMEType);
	NSLog(@"textEncodingName: %@",response.textEncodingName);
	NSLog(@"suggestedFilename: %@",response.suggestedFilename);
	if ([httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {		
		NSLog(@"statusCode: %i",httpResponse.statusCode);
		NSLog(@"allHeaderFields: %@",httpResponse.allHeaderFields);
	}
}

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)data {
	NSLog(@"DigitalLockerConnection connection:%@ didReceiveData: %@",aConnection,data);
	[_responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
	NSString * stringData = [[[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding] autorelease];
	NSLog(@"stringData: %@",stringData);
	NSXMLParser * parser = [[NSXMLParser alloc] initWithData:_responseData];
	parser.delegate = self;
	[parser parse];
	[parser release];
	if (self.delegate) [self.delegate connectionDidFinishLoading:self];
}
- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error {
	NSLog(@"DigitalLockerConnection connection:%@ didFailWithError: %@, %@",aConnection,error,[error localizedDescription]);
	if (self.delegate) [self.delegate connection:self didFailWithError:error];
}

// TODO: consider taking the two delegate methods below out for final release, as this is a work-around for B&T's godaddy certificate (reads as invalid)!
- (BOOL)connection: ( NSURLConnection * )connection canAuthenticateAgainstProtectionSpace: ( NSURLProtectionSpace * ) protectionSpace {
	NSLog(@"DigitalLockerConnection connection:%@ canAuthenticateAgainstProtectionSpace: %@",connection, protectionSpace);
	return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {  
	NSLog(@"DigitalLockerConnection connection:%@ didReceiveAuthenticationChallenge: %@",connection, challenge);
    //if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])  
	//if ([trustedHosts containsObject:challenge.protectionSpace.host])  
	[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];  
	
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];  
}  

#pragma mark -
#pragma mark NSXMLParserDelegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	//	NSLog(@"didStartElement: %@",elementName);
	if ( [elementName isEqualToString:@"Response"] ) {
		self.digitalLockerResponse = [[[DigitalLockerResponse alloc] init] autorelease];
		self.digitalLockerResponse.parent = self;
		parser.delegate = self.digitalLockerResponse;
	}
}
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	//	NSLog(@"found characters: %@",string);
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {    
	//	NSLog(@"didEndElement: %@",elementName);
	if ( [elementName isEqualToString:@"Gateway"] ) {
		// we're done.
	}
}

@end
