//
//  KDRMLicenseStore.h
//  KDRMClient
//
//  Created by Glenn Martin on 7/13/12.
//  Copyright (c) 2012 Intrepid Pursuits, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KDRMLicense.h"
#import "KDRMJWSMessage.h"

extern NSString* const KDRMLicenseStoreErrorDomain;

@protocol KDRMLicenseDecryptor; /* KDRMSilverlightClient.Decryptor */

@interface KDRMLicenseStore : NSObject /* KDRMSilverlightClient.LicenseStore */
+(NSString*) hardwareHash;
+(KDRMLicenseStore *) sharedLicenseStore;

-(void) clear;
-(NSString*) devicePublicKeyPEM;
-(NSString*) devicePrivateKeyPEM;
+(NSString*) serverPublicKeyPEM;
-(NSString*) serverPublicKeyPEM;
-(NSSet*) licenses;
-(NSString*) hardwareHash;

-(KDRMJWSMessageSigningBlock) appKeySigningBlock;

-(NSError*) importLicense:(KDRMLicense*)license;

-(NSData*) symetricEncrypt:(NSData*)data key:(NSData*)key  initializationVector:(NSData*)vector;
-(id<KDRMLicenseDecryptor>) decryptorForLicense:(KDRMLicense*)license;
@end

@protocol KDRMLicenseDecryptor <NSObject>
-(NSData*) decryptData:(NSData*)data;
@end