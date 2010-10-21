//
//  DigitalLockerGateway.m
//  BlioApp
//
//  Created by Don Shin on 9/16/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import "DigitalLockerGateway.h"
#import "NSString+BlioAdditions.h"
#import "UIDevice+BlioAdditions.h"

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

+(NSString*)serializeDictionary:(NSDictionary*)dictionary withName:(NSString*)aName {
	NSMutableString * serialization = [NSMutableString string];
	if (aName) [serialization appendString:[NSString stringWithFormat:@"<%@>",aName]];
	for (id key in dictionary)
	{
		if ([key isKindOfClass:[NSString class]]) {
			id valueForKey = [dictionary objectForKey:key];
			if (valueForKey && [valueForKey isKindOfClass:[NSString class]]) [serialization appendString:[NSString stringWithFormat:@"<%@>%@</%@>",key,valueForKey,key]];
			else if (valueForKey && [valueForKey isKindOfClass:[NSDictionary class]]) [DigitalLockerXMLObject serializeDictionary:valueForKey withName:nil];
		}
	}
	if (aName) [serialization appendString:[NSString stringWithFormat:@"</%@>",aName]];
	return serialization;
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

@implementation DigitalLockerState

@synthesize ClientIPAddress = _ClientIPAddress;
@synthesize ClientDomain = _ClientDomain;
@synthesize ClientLanguage = _ClientLanguage;
@synthesize ClientLocation = _ClientLocation;
@synthesize ClientUserAgent = _ClientUserAgent;
@synthesize SiteKey = _SiteKey;
@synthesize AppID = _AppID;

static NSString * SessionId = nil;

-(id)init {
	self = [super init];
	if (self) {
		_ClientIPAddress = [UIDevice IPAddress];
		[_ClientIPAddress retain];
		_ClientDomain = @"gw.bliodigitallocker.net";
		[_ClientDomain retain];
		_ClientLanguage = @"en";
		[_ClientLanguage retain];
		_ClientLocation = @"US";
		[_ClientLocation retain];
		_ClientUserAgent = [NSString stringWithFormat:@"Blio iPhone/%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
		[_ClientUserAgent retain];
		_SiteKey = DigitalLockerBlioIOSSiteKey;
		[_SiteKey retain];
		_AppID = DigitalLockerBlioAppID;
		[_AppID retain];
	}	
	return self;	
}

+(NSString *) SessionId {
	if (SessionId == nil) {
		SessionId = [[NSString alloc] initWithString:@"NEW"];
	}
	return SessionId;
}
+(void) setSessionId:(NSString *)sessionId {
	if (SessionId) [SessionId release];
	SessionId = [[NSString alloc] initWithString:sessionId];
}

-(NSString *) serialize {
	NSArray * keys = [NSArray arrayWithObjects:@"ClientIPAddress",@"ClientDomain",@"ClientLanguage",@"ClientLocation",@"SiteKey",nil];
	NSMutableString * serialization = [NSMutableString stringWithString:@"<State>"];
	
	for (NSString* key in keys) {
		NSString * valueForKey = [self valueForKey:key];
		if (valueForKey) [serialization appendString:[NSString stringWithFormat:@"<%@>%@</%@>",key,valueForKey,key]];
	}
	NSString * systemNameVersion = [NSString stringWithFormat:@"%@/%@",[[UIDevice currentDevice] systemName],[[UIDevice currentDevice] systemVersion]];
	NSString * hash = [[DigitalLockerBlioAppID md5Hash] substringWithRange:NSMakeRange(5, 6)];
	[serialization appendString:[NSString stringWithFormat:@"<ClientUserAgent>%@; %@; %@%@</ClientUserAgent>", self.ClientUserAgent,systemNameVersion, self.AppID,hash]];
	[serialization appendString:@"</State>"];
	NSLog(@"serialization: %@",serialization);
	return serialization;
}

-(void) dealloc {
	if (_ClientIPAddress) [_ClientIPAddress release];
	if (_ClientDomain) [_ClientDomain release];
	if (_ClientLanguage) [_ClientLanguage release];
	if (_ClientLocation) [_ClientLocation release];
	if (_ClientUserAgent) [_ClientUserAgent release];
	if (_SiteKey) [_SiteKey release];
	if (_AppID) [_AppID release];
	[super dealloc];
}


@end

@implementation DigitalLockerRequest
@synthesize Service,Method,InputData;

-(void) dealloc {
	self.Service = nil;
	self.Method = nil;
	self.InputData = nil;
	[super dealloc];
}

-(NSString *) serialize {
	NSArray * keys = [NSArray arrayWithObjects:@"Service",@"Method",@"InputData",nil];
	NSMutableString * serialization = [NSMutableString stringWithString:@"<Request>"];
	
	for (NSString* key in keys) {
		id valueForKey = [self valueForKey:key];
		if (valueForKey && [valueForKey isKindOfClass:[NSString class]]) [serialization appendString:[NSString stringWithFormat:@"<%@>%@</%@>",key,(NSString*)valueForKey,key]];
		else if (valueForKey && [valueForKey isKindOfClass:[NSDictionary class]]) [serialization appendString:[NSString stringWithFormat:@"<%@>%@</%@>",key,[DigitalLockerXMLObject serializeDictionary:(NSDictionary*)valueForKey withName:nil],key]];
	}
	[serialization appendString:@"</Request>"];
	NSLog(@"serialization: %@",serialization);
	return serialization;
}

@end

@implementation DigitalLockerConnection

@synthesize Request = _Request;
@synthesize State = _State;
@synthesize delegate = _delegate;
@synthesize digitalLockerResponse,urlConnection,parserDelegateStack;

-(id)initWithDigitalLockerRequest:(DigitalLockerRequest*)aRequest delegate:(id)delegate {
	if (!aRequest) return nil;
	self = [super init];
	if (self)
	{
		self.Request = aRequest;
		self.delegate = delegate;
		
		_State = [[DigitalLockerState alloc] init];

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
		
		NSString * requestString = [NSString stringWithFormat:@"request=<Gateway version=\"4.1\" debug=\"1\">%@%@</Gateway>",[self.State serialize],[self.Request serialize]];
		NSLog(@"requestString: %@",requestString);
		NSData *postData = [requestString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
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
	if (_Request) [_Request release];
	self.delegate = nil;
	if (_State) [_State release];
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