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

#import <Foundation/Foundation.h>

/**
 A class that represents an access token when authenticated from Windows Azure Access Control Service (ACS).
 */
@interface WACloudAccessToken : NSObject

/**
 The audeince for the token.
 */
@property (readonly) NSString *appliesTo;

/**
 The token type.
 */
@property (readonly) NSString *tokenType;

/**
 The expiration time for the token.
 */
@property (readonly) NSInteger expires;

/**
 The create time for the token.
 */
@property (readonly) NSInteger created;

/**
 The expiration date for the token.
 */
@property (readonly) NSDate *expireDate;

/**
	The creation date for the token.
 */
@property (readonly) NSDate *createDate;

/**
 The security token to sign requests.
 */
@property (readonly) NSString *securityToken;

/**
 The identity provider for the token
 */
@property (readonly) NSString *identityProvider;

/**
 The claims associated with the token.
 */
@property (readonly) NSDictionary *claims;

/**
 Signs the request and adds the OAuth token.
 
 @param request The request to sign.
 */
- (void)signRequest:(NSMutableURLRequest *)request;

@end
