//
//  BlioXPSProtocol.m
//  BlioApp
//
//  Created by Matt Farrugia on 07/04/2011.
//  Copyright 2011 BitWink. All rights reserved.
//

#import "BlioXPSProtocol.h"
#import "BlioBookManager.h"
#import "BlioXPSProvider.h"

@implementation BlioXPSProtocol

+ (void)registerXPSProtocol {
	static BOOL inited = NO;
	if ( ! inited ) {
		[NSURLProtocol registerClass:[BlioXPSProtocol class]];
		inited = YES;
	}
}

/* our own class method.  Here we return the NSString used to mark
 urls handled by our special protocol. */
+ (NSString *)xpsProtocolScheme {
	return @"blioxpsprotocol";
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
	NSString *theScheme = [[request URL] scheme];
	return ([theScheme caseInsensitiveCompare: [BlioXPSProtocol xpsProtocolScheme]] == NSOrderedSame);
}

/* if canInitWithRequest returns true, then webKit will call your
 canonicalRequestForRequest method so you have an opportunity to modify
 the NSURLRequest before processing the request */
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
	
	
	/* retrieve the current request. */
    NSURLRequest *request = [self request];
	NSString *encodedBookID = [[request URL] host];
	
	NSManagedObjectID *bookID = nil;
	
	if (encodedBookID && ![encodedBookID isEqualToString:@"undefined"]) {
		CFStringRef bookURIStringRef = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (CFStringRef)encodedBookID, CFSTR(""), kCFStringEncodingUTF8);		
		NSURL *bookURI = [NSURL URLWithString:(NSString *)bookURIStringRef];
		CFRelease(bookURIStringRef);
        
		bookID = [[[BlioBookManager sharedBookManager] persistentStoreCoordinator] managedObjectIDForURIRepresentation:bookURI];
		
	}
	
	if (!bookID) {
		return;
	}
	
	BlioXPSProvider *xpsProvider = [[BlioBookManager sharedBookManager] checkOutXPSProviderForBookWithID:bookID];
	
	NSString *path = [[request URL] path];
	NSData *data = [xpsProvider dataForComponentAtPath:path];
	
	NSURLResponse *response = 
	[[NSURLResponse alloc] initWithURL:[request URL] 
							  MIMEType:nil 
				 expectedContentLength:-1 
					  textEncodingName:@"utf-8"];
	
	/* get a reference to the client so we can hand off the data */
    id<NSURLProtocolClient> client = [self client];
	
	/* turn off caching for this response data */ 
	[client URLProtocol:self didReceiveResponse:response
	 cacheStoragePolicy:NSURLCacheStorageNotAllowed];
	
	/* set the data in the response to our data */ 
	[client URLProtocol:self didLoadData:data];
	
	/* notify that we completed loading */
	[client URLProtocolDidFinishLoading:self];
	
	/* we can release our copy */
	[response release];
	
	[[BlioBookManager sharedBookManager] checkInXPSProviderForBookWithID:bookID];
	
}

- (void)stopLoading {
	// Do nothing
}

@end