//
//  KDRMJWSMessage.h
//  KDRMClient
//
//  Created by Glenn Martin on 7/16/12.
//  Copyright (c) 2012 Intrepid Pursuits, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSData* (^KDRMJWSMessageSigningBlock)(NSData* dataToSign);

@interface KDRMJWSMessage : NSObject
@property (nonatomic, readonly, copy) NSString* message;
@property (nonatomic, readonly, copy) NSDictionary* header;
@property (nonatomic, readonly, copy) NSData* signature;
@property (nonatomic, readonly, copy) NSString* rawInput;

+(id)message:(NSString*)message sign:(KDRMJWSMessageSigningBlock)sign;
+(id)message:(NSString*)message headers:(NSDictionary*)headers sign:(KDRMJWSMessageSigningBlock)sign;
+(id)message:(NSString*)message header:(NSString*)header sign:(KDRMJWSMessageSigningBlock)sign;
+(id)parse:(NSString*)string;

-(BOOL) isSignatureValid;
-(NSString*) serialize;
@end
