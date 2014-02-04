/*
 Copyright 2010 Microsoft Corp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "WACloudURLRequest.h"
#import "WAXMLHelper.h"
#import "Logging.h"
#import <libxml/parser.h>
#import "UIApplication+WANetworkActivity.h"

NSString * const WANextPartitionKeyHeader = @"X-Ms-Continuation-Nextpartitionkey";
NSString * const WANextRowKeyHeader = @"X-Ms-Continuation-Nextrowkey";
NSString * const WANextTableKeyHeader = @"X-Ms-Continuation-Nexttablename";

#define SELF_SIGNED_SSL 1 // indicates that the library supports self signed SSL certs

#if SELF_SIGNED_SSL
static NSString* proxyAddress = nil;
#endif

#if USE_QUEUE
static WACloudURLRequest* _head = nil;
static WACloudURLRequest* _tail = nil;
static NSLock* _lock;
#endif

@implementation WACloudURLRequest

@synthesize nextRowKey = _nextRowKey;
@synthesize nextPartitionKey = _nextPartitionKey;
@synthesize nextTableKey = _nextTableKey;

void ignoreSSLErrorFor(NSString* host)
{
#if SELF_SIGNED_SSL
	[proxyAddress release];
	proxyAddress = [[NSString stringWithFormat:@"%@.cloudapp.net", host] copy];
#endif
}

#if USE_QUEUE
#pragma mark Request Queuing support

- (void)append:(WACloudURLRequest*)request
{
    _tail = _next = [request retain];
}

- (WACloudURLRequest*)next
{
    return _next;
}

- (void)startNext
{
    [_lock lock];
    @try
    {
        WACloudURLRequest* next = [_head next];
        [_head release];
        if(next)
        {
            _head = next;
            [[UIApplication sharedApplication] wa_pushNetworkActivity];
            [NSURLConnection connectionWithRequest:_head delegate:_head];
        }
        else
        {
            _head = _tail = nil;
        }
    }
    @finally 
    {
        [_lock unlock];
    }
}

- (void)queueRequest
{
    if(!_lock)
    {
        _lock = [[NSLock alloc] init];
    }
    
    [_lock lock];
    @try
    {
        if(_tail)
        {
            [_tail append:self];
        }
        else
        {
            _head = _tail = [self retain];
            [[UIApplication sharedApplication] wa_pushNetworkActivity];
            // if I'm the first in queue, start me right away
            [NSURLConnection connectionWithRequest:self delegate:self];
        }
    }
    @finally 
    {
        [_lock unlock];
    }
}

#pragma mark -
#endif

- (void)fetchNoResponseWithCompletionHandler:(WANoResponseHandler)block
{
    _noResponseBlock = [block copy];

	WA_BEGIN_LOGGING
		NSLog(@"Request URL: %@", [self URL]);
	WA_END_LOGGING
	
#if USE_QUEUE
    [self queueRequest];
#else
    [[UIApplication sharedApplication] wa_pushNetworkActivity];
	[NSURLConnection connectionWithRequest:self delegate:self];
#endif
}

- (void)fetchXMLWithCompletionHandler:(WAFetchXMLHandler)block
{
    _xmlBlock = [block copy];
	
	WA_BEGIN_LOGGING
		NSLog(@"Request URL: %@", [self URL]);
	WA_END_LOGGING
	
#if USE_QUEUE
    [self queueRequest];
#else
    [[UIApplication sharedApplication] wa_pushNetworkActivity];
	[NSURLConnection connectionWithRequest:self delegate:self];
#endif
}

- (void)fetchDataWithCompletionHandler:(WAFetchDataHandler)block
{
    _dataBlock = [block copy];
	
	WA_BEGIN_LOGGING
		NSLog(@"Request URL: %@", [self URL]);
	WA_END_LOGGING
	
#if USE_QUEUE
    [self queueRequest];
#else
    [[UIApplication sharedApplication] wa_pushNetworkActivity];
	[NSURLConnection connectionWithRequest:self delegate:self];
#endif
}

- (void)dealloc
{
    [_nextPartitionKey release];
    [_nextRowKey release];
	[_nextTableKey release];
	[_noResponseBlock release]; 
	[_xmlBlock release]; 
	[_dataBlock release]; 
	[_data release]; 
	[_contentType release];
    
	[super dealloc];
}

- (void)sendDataResponse:(NSData*)data error:(NSError*)err 
{
    if(_dataBlock)
    {
        _dataBlock(self, data, err);
        return;
    }
}

- (void)sendDocumentResponse:(xmlDocPtr)doc error:(NSError*)err 
{
    if(_xmlBlock)
    {
        _xmlBlock(self, doc, err);
        return;
    }
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    
    if ([response respondsToSelector:@selector(allHeaderFields)]) {
		NSDictionary *dictionary = [httpResponse allHeaderFields];
        WA_BEGIN_LOGGING_CUSTOM(WALoggingResponse)
            NSLog(@"Status Code - %d", [httpResponse statusCode]);
            NSLog(@"Respone Headers: %@", [dictionary description]);
        WA_END_LOGGING
        _statusCode = [httpResponse statusCode];
        _nextPartitionKey = [[dictionary objectForKey:WANextPartitionKeyHeader] copy];
        _nextRowKey = [[dictionary objectForKey:WANextRowKeyHeader] copy];
        _nextTableKey = [[dictionary objectForKey:WANextTableKeyHeader] copy];
    }
    
    _expectedContentLength = [response expectedContentLength];
	_contentType = [[response MIMEType] copy];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if (!_data) {
		_data = [data mutableCopy];
	} else {
		[_data appendData:data];
	}
}

#ifdef SELF_SIGNED_SSL

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
	return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if (proxyAddress && [challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
		if ([challenge.protectionSpace.host isEqualToString:proxyAddress]) {
			NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
			[challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
		}
	}
	[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}
#endif

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (_contentType && [_contentType compare:@"text/html" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
		NSString *htmlStr = [[[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding] autorelease];
		NSError *regexError;
		NSError *contentError = nil;
		NSRegularExpression *message = [NSRegularExpression regularExpressionWithPattern:@"<h2>(.*?)<\\/h2>"
																					   options:NSRegularExpressionDotMatchesLineSeparators 
																						 error:&regexError];
		NSTextCheckingResult *result = [message firstMatchInString:htmlStr options:0 range:NSMakeRange(0, htmlStr.length)];
		int found = [result numberOfRanges];
		if(found == 2) {
			// need to convert this into an error...
			NSRange r = [result rangeAtIndex:1];
			NSString *msg = [htmlStr substringWithRange:r];
			contentError = [NSError errorWithDomain:@"com.microsoft.WAToolkit" 
											   code:-1 
										   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                     msg, NSLocalizedDescriptionKey, 
                                                     htmlStr, NSLocalizedFailureReasonErrorKey, nil]];
		}
        
		if (contentError) {
			[self connection:connection didFailWithError:contentError];
			return;
		}
	}
    
    WA_BEGIN_LOGGING_CUSTOM(WALoggingResponse)
        if (_data) {
            NSString *xmlStr = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
            NSLog(@"XML response: %@", xmlStr);
            [xmlStr release];
        }
    WA_END_LOGGING
    
    BOOL continueToNext = YES;
    
    const char *baseURL = NULL;
    const char *encoding = NULL;
    
    xmlDocPtr doc = NULL;
    NSError *error = nil;
    if (_data) {
        doc = xmlReadMemory([_data bytes], (int)[_data length], baseURL, encoding, (XML_PARSE_NOCDATA | XML_PARSE_NOBLANKS)); 
        error = [WAXMLHelper checkForError:doc withStatusCode:_statusCode];
    }
    
    if (_statusCode == 401) {
        NSString *message = nil;
        if (doc) {
            message = [WAXMLHelper getStringErrorValue:doc];
        } else {
            message = [NSHTTPURLResponse localizedStringForStatusCode:_statusCode];
        }
        NSString *detail = [NSHTTPURLResponse localizedStringForStatusCode:_statusCode];        
        NSError *contentError = [NSError errorWithDomain:@"com.microsoft.WAToolkit" 
                                                    code:_statusCode
                                                userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          message, NSLocalizedDescriptionKey, 
                                                          detail, NSLocalizedFailureReasonErrorKey, nil]];
        
        if (contentError) {
			[self connection:connection didFailWithError:contentError];
		}
        continueToNext = NO;
    } else if (_noResponseBlock) {
        if (error) {
            _noResponseBlock(self, error);
        } else {
            _noResponseBlock(self, nil);
        }
    } else if (_xmlBlock) {   
        if (error) {
            _xmlBlock(self, nil, error);
        } else {
            _xmlBlock(self, doc, nil);
        }
	} else if (_dataBlock) {
        if (error) {
            _dataBlock(self, nil, error);
        } else {
            _dataBlock(self, _data, nil);
        }
	}
    
    if (doc) {
        xmlFreeDoc(doc);
    }
    
    [[UIApplication sharedApplication] wa_popNetworkActivity];
    
#if USE_QUEUE
    if (continueToNext == YES) {
        [self startNext];
    }
#endif
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (_noResponseBlock) {
        _noResponseBlock(self, error);
    } else if (_xmlBlock) {
        _xmlBlock(self, nil, error);
    } else if(_dataBlock) {
        _dataBlock(self, nil, error);
    }
    [[UIApplication sharedApplication] wa_popNetworkActivity];
    
#if USE_QUEUE
    [self startNext];
#endif
}

#pragma mark -

@end


@implementation NSString (URLEncode)

- (NSString*) URLEncode
{
	NSString *result = (NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, CFSTR(":/?#[]@!$&’()* +,;="), kCFStringEncodingUTF8); 
	return [result autorelease]; 
}

- (NSString*) URLDecode
{
	NSString *result = (NSString *) CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (CFStringRef)self, CFSTR(""), kCFStringEncodingUTF8); 
	[result autorelease]; 
	
	return [result stringByReplacingOccurrencesOfString:@"+" withString:@" "];
}

@end
