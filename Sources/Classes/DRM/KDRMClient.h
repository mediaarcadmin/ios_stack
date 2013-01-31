//
//  KDRMClient.h
//  KDRMClient
//
//  Created by Glenn Martin on 7/16/12.
//  Copyright (c) 2012 Intrepid Pursuits, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KDRMLicense.h"

extern NSString* const KDRMClientErrorDomain;

typedef enum {
    KDRMClientErrorDomainCodeInvalidHTTPStatusCode,
    KDRMClientErrorDomainCodeInvalidServerStatusCode,
    KDRMClientErrorDomainCodeInvalidLicenseData,
    KDRMClientErrorDomainCodeInvalidSignature,
    KDRMClientErrorDomainCodeMissingLicense,
    KDRMClientErrorDomainCodeExpiredLicense
} KDRMClientErrorDomainCode;

typedef void (^KDRMClientLicenseCompletion)(NSURLRequest* request, NSURLResponse* response, NSError* error, KDRMLicense* license);

typedef void (^KDRMClientDeregisterCompletion)(NSURLRequest* request, NSURLResponse* response, NSError* error);

// AC 
typedef void (^KDRMClientBindCompletion)(NSError* error);

@interface KDRMRequest : NSOperation 
@property (nonatomic, readonly) NSURLRequest* request;
@end

@interface KDRMClient : NSObject /* KDRMSilverlightClient.LicenseAcquirer */

-(BOOL)acquireLicenseForISBNSync:(NSString*)isbn
                               token:(NSString*)token
                                 url:(NSString*)url
                          completion:(KDRMClientLicenseCompletion)complete;

-(KDRMRequest*)acquireLicenseForISBN:(NSString*)isbn 
                               token:(NSString*)token 
                                 url:(NSString*)url 
                          completion:(KDRMClientLicenseCompletion)complete;

-(BOOL)deregister:(NSString*)token
                             url:(NSString*)url
                      completion:(KDRMClientDeregisterCompletion)complete;

-(BOOL)bindToLicense:(NSString*)isbn license:(KDRMLicense**)license completion:(KDRMClientBindCompletion)complete;

@end
