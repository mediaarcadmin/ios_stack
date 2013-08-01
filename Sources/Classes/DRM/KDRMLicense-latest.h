//
//  KDRMLicense.h
//  KDRMClient
//
//  Created by Colin Brash on 7/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KDRMJWSMessage.h"

@interface KDRMLicense : NSObject <NSCoding, NSCopying> /* KDRMSilverlightClient.License */

@property (nonatomic, readonly) NSData *rawLicense;
@property (nonatomic, retain) KDRMJWSMessage *jwsMessage;
@property (nonatomic, readonly) NSDate *timestamp;
@property (nonatomic, readonly) NSString *userId;
@property (nonatomic, readonly) NSData *key;
@property (nonatomic, readonly) NSString *version;
@property (nonatomic, readonly) NSString *hardwareHash;
@property (nonatomic, readonly) NSString *isbn;
@property (nonatomic, readonly) NSDate *expiration;

+(id) parseFromString:(NSString*)jsonString;
+(id) parseFromData:(NSData*)jsonData;
+(id) parseFromDictionary:(NSDictionary*)jsonDict;

@end