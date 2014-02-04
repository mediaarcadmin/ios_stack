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

#import "WACloudAccessToken.h"
#import <libxml/tree.h>
#import "WASimpleBase64.h"
#import "WACloudAccessControlClient.h"
#import "WACloudAccessControlHomeRealm.h"
#import "NSString+URLEncode.h"

@implementation WACloudAccessToken

@synthesize appliesTo = _appliesTo;
@synthesize tokenType = _tokenType;
@synthesize expires = _expires;
@synthesize created = _created;
@synthesize securityToken = _securityToken;
@synthesize identityProvider = _identityProvider;
@synthesize claims = _claims;

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    if((self = [super init]))
    {
        _appliesTo = [[dictionary objectForKey:@"appliesTo"] retain];
        _tokenType = [[dictionary objectForKey:@"tokenType"] retain];
        _expires = [[dictionary objectForKey:@"expires"] integerValue];
        _created = [[dictionary objectForKey:@"created"] integerValue];
		_identityProvider = @""; //[realm.name retain];
        
        NSString *securityTokenXmlStr = [dictionary objectForKey:@"securityToken"];
        
        securityTokenXmlStr = [securityTokenXmlStr stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
        securityTokenXmlStr = [securityTokenXmlStr stringByReplacingOccurrencesOfString:@"&apos;" withString:@"\'"];
        securityTokenXmlStr = [securityTokenXmlStr stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
        securityTokenXmlStr = [securityTokenXmlStr stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
        securityTokenXmlStr = [securityTokenXmlStr stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
        
        NSRange r = [securityTokenXmlStr rangeOfString:@"?>"];
        if(r.length)
        {
            r = [securityTokenXmlStr rangeOfString:@"<" options:0 range:NSMakeRange(r.location, securityTokenXmlStr.length - r.location)];
            if(r.length)
            {
                securityTokenXmlStr = [securityTokenXmlStr substringFromIndex:r.location];
            }
        }
        
        NSData *data = [securityTokenXmlStr dataUsingEncoding:NSUTF8StringEncoding];
        const char *baseURL = NULL;
        const char *encoding = NULL;
        
        xmlDocPtr doc = xmlReadMemory([data bytes], (int)[data length], baseURL, encoding, (XML_PARSE_NOCDATA | XML_PARSE_NOBLANKS)); 
        
        if (doc != NULL) 
        {
            xmlNodePtr root = xmlFirstElementChild((xmlNodePtr) doc);
            xmlChar *xmlValue = xmlNodeGetContent(root);
            
            NSString *securityTokenEncoded = [NSString stringWithCString:(const char*)xmlValue encoding:NSUTF8StringEncoding];
            NSData *securityTokenData = [securityTokenEncoded dataWithBase64DecodedString];
			
			xmlFree(xmlValue);
            
            _securityToken = [[NSString alloc] initWithData:securityTokenData encoding:NSUTF8StringEncoding];
			
			NSMutableDictionary *claims = [NSMutableDictionary dictionaryWithCapacity:10];
			
			for(NSString *part in [_securityToken componentsSeparatedByString:@"&"])
			{
				NSRange split = [part rangeOfString:@"="];
				if(!split.length)
				{
					continue; // weird
				}
				
				NSString *key = [[part substringToIndex:split.location] URLDecode];
				NSString *value = [[part substringFromIndex:split.location + 1] URLDecode];
				
                [claims setObject:value forKey:key];
			}
			
			_claims = [claims copy];
            
            xmlFreeDoc(doc);
        }
    }
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"CloudAccessToken: { appliesTo = %@, tokenType = %@, expireDate = %@, createDate = %@, securityToken = %@, claims = %@ }",
            _appliesTo, _tokenType, [self expireDate], [self createDate], _securityToken, _claims];
}

- (void)dealloc
{
    [_appliesTo release];
    [_tokenType release];
    [_securityToken release];
	[_identityProvider release];
	[_claims release];
    
    [super dealloc];
}

- (NSDate *)expireDate
{
    return [NSDate dateWithTimeIntervalSince1970:_expires];
}

- (NSDate *)createDate
{
    return [NSDate dateWithTimeIntervalSince1970:_created];
}

- (void)signRequest:(NSMutableURLRequest *)request
{
	NSString *authHeader = [NSString stringWithFormat:@"OAuth %@", _securityToken];
	[request setValue:authHeader forHTTPHeaderField:@"Authorization"];
}

@end
