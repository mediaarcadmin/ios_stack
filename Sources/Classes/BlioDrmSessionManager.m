//
//  BlioDrmSessionManager.m
//  BlioApp
//
//  Created by Arnold Chien on 8/25/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import "BlioDrmSessionManager.h"
#import "XpsSdk.h"
#import "BlioBook.h"
#import "BlioXPSProvider.h"
#import "BlioAlertManager.h"
#import "BlioAppSettingsConstants.h"
#import "BlioStoreHelper.h"
#import "KDRMLicenseStore.h"
#import "KDRMClient.h"
#import "MediaArcPlatform.h"

@interface BlioDrmSessionManager()

@property (nonatomic, retain) KDRMLicense* license;
@property (nonatomic, retain) NSString* isbn;

@end

@implementation BlioDrmSessionManager

@synthesize license, isbn;

-(void)reportError:(NSError*)error {
    if ([error.domain compare:@"KDRMClientErrorDomain"] == NSOrderedSame) {
        switch (error.code) {
            case KDRMClientErrorDomainCodeInvalidHTTPStatusCode: 
                [BlioAlertManager showAlertOfSuppressedType:BlioDrmFailureAlertType
                                                      title:NSLocalizedString(@"Rights Management Error",@"\"Rights Management Error\" alert message title")
                                                    message:error.localizedDescription
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
                break;
            case KDRMClientErrorDomainCodeInvalidServerStatusCode:
                [BlioAlertManager showAlertOfSuppressedType:BlioDrmFailureAlertType
                                                      title:NSLocalizedString(@"Rights Management Error",@"\"Rights Management Error\" alert message title")
                                                    message:error.localizedDescription
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
                break;
            case KDRMClientErrorDomainCodeInvalidLicenseData:
                [BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Rights Management Error",@"\"Rights Management Error\" alert message title")
                                                    message:NSLocalizedStringWithDefaultValue(@"INVALID_LICENSE_DATA",
                                                                                              nil,
                                                                                              [NSBundle mainBundle],
                                                                                              @"The license data is invalid.",
                                                                                              @"Description of invalid license data error.")
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
                break;
            case KDRMClientErrorDomainCodeInvalidSignature:
                [BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Rights Management Error",@"\"Rights Management Error\" alert message title")
                                                    message:NSLocalizedStringWithDefaultValue(@"INVALID_LICENSE_SIGNATURE",
                                                                                              nil,
                                                                                              [NSBundle mainBundle],
                                                                                              @"The license signature is invalid.",
                                                                                              @"Description of invalid license signature error.")
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
                break;
            case KDRMClientErrorDomainCodeMissingLicense:
                [BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Rights Management Error",@"\"Rights Management Error\" alert message title")
                                                    message:NSLocalizedStringWithDefaultValue(@"MISSING_LICENSE",
                                                                                              nil,
                                                                                              [NSBundle mainBundle],
                                                                                              @"The book could not be opened because the license is missing.",
                                                                                              @"Description of missing license error.")
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
                break;
            case KDRMClientErrorDomainCodeExpiredLicense:
                [BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Rights Management Error",@"\"Rights Management Error\" alert message title")
                                                    message:NSLocalizedStringWithDefaultValue(@"EXPIRED_LICENSE",
                                                                                              nil,
                                                                                              [NSBundle mainBundle],
                                                                                              @"The book could not be opened because it is past its due date.",
                                                                                              @"Description of expired license error.")
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
                break;
            default:
                break;
        }
    }
    else if ([error.domain compare:@"KDRMLicenseStoreErrorDomain"] == NSOrderedSame) {
        [BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Rights Management Error",@"\"Rights Management Error\" alert message title")
                                            message:error.localizedDescription
                                           delegate:nil
                                  cancelButtonTitle:nil
                                  otherButtonTitles:@"OK", nil];
    }
}

-(void) dealloc {
    self.license = nil;
    self.isbn = nil;
	[super dealloc];
}

- (id)initWithBookID:(NSManagedObjectID *)aBookID 
{
    if((self = [super init])) {
        BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:aBookID];
        self.isbn = [book valueForKey:@"isbn"];
        self.license = nil;
    }
    return self;
}


- (BOOL)getLicenseKDRM:(NSString*)token {
    KDRMClient* client = [[KDRMClient alloc] init];
    NSString* licenseURL = @"https://";
    licenseURL = [licenseURL stringByAppendingString:[[[MediaArcPlatform sharedInstance] drmHost]
                                                      stringByAppendingString:[[MediaArcPlatform sharedInstance] licenseAcquisitionURL]]];
    BOOL success = [client acquireLicenseForISBNSync:self.isbn
                                               token:token
                                                 url:licenseURL
                                          completion:^(NSURLRequest *request, NSURLResponse *response, NSError *error, KDRMLicense *lic) {
                                              NSString* logMsg = [NSString stringWithFormat:@"(%@, %@, %@, %@)", request, response, error, lic];
                                              NSLog(@"%@",logMsg);
                                              if ( error==nil )
                                                  NSLog(@"Acquired KDRM License.");
                                              else
                                                  [self reportError:error];
                                          }
                    ];
    [client release];
    if ( success )
		[[BlioStoreManager sharedInstance] setDeviceRegisteredSettingOnly:BlioDeviceRegisteredStatusRegistered forSourceID:BlioBookSourceOnlineStore];
    return success;
}

- (BOOL)getLicense:(NSString*)token {
    return [self getLicenseKDRM:token];
}

- (BOOL)bindToLicenseKDRM { 
    KDRMClient* client = [[KDRMClient alloc] init];
    KDRMLicense* lic;
    BOOL success = [client bindToLicense:self.isbn
                                  license:&lic
                           completion:^(NSError *error) {
                               NSString* logMsg = [NSString stringWithFormat:@"(%@)", error];
                               NSLog(@"%@",logMsg);
                               if ( error==nil )
                                   NSLog(@"KDRM bind successful.");
                               else
                                   [self reportError:error];
                           }
                    ];
    [client release];
    if (success)
        self.license = lic;
    return success;
}

- (BOOL)bindToLicense {
    return [self bindToLicenseKDRM];
}

- (BOOL)decryptDataKDRM:(NSData *)data {
    
    if (!self.license)
        if (![self bindToLicenseKDRM])
            return NO;
    
    id<KDRMLicenseDecryptor> decryptor = [[KDRMLicenseStore sharedLicenseStore] decryptorForLicense:self.license];
    NSData* decryptedData = [decryptor decryptData:data];
    // Unlike other KDRM operations, decryption doesn't return any error code.
    if (!decryptedData)
        return NO;
    
    // The data isn't supposed to change, so we do it underneath NSData.
    // For future, the libKNFBReader signature should change so that we have an NSMutableData, but 
    // we leave it for now as NSData to accommodate other consumers of libKNFBReader not on KDRM.
    if ([decryptedData length] <= [data length])
        // Should always be the case
        memcpy((void*)[data bytes],[decryptedData bytes],[decryptedData length]);
    else
        return NO;
    
    /* Would like: 
    NSRange replacementRange = {0,[decryptedData length]};
    [mutableData setLength:[decryptedData length]];
    [mutableData replaceBytesInRange:replacementRange withBytes:[decryptedData bytes]];
    */
    
    return YES;
}

- (BOOL)decryptData:(NSMutableData *)data {
    return [self decryptDataKDRM:data];
}

- (BOOL)leaveDomainKDRM:(NSString*)token {
    
    KDRMClient* client = [[KDRMClient alloc] init];
    NSString* deregistrationURL = @"http://";
    deregistrationURL = [deregistrationURL stringByAppendingString:[[[MediaArcPlatform sharedInstance] drmHost]
                                                                    stringByAppendingString:[[MediaArcPlatform sharedInstance] deregistrationURL]]];
    BOOL success = [client deregister:token
                                  url:deregistrationURL
                           completion:^(NSURLRequest *request, NSURLResponse *response, NSError *error) {
                               NSString* logMsg = [NSString stringWithFormat:@"(%@, %@, %@)", request, response, error];
                               NSLog(@"%@",logMsg);
                               if ( error==nil )
                                   NSLog(@"KDRM deregistration successful.");
                               else
                                   [self reportError:error];
                           }
                    ];
    [client release];
    if ( success )
		[[BlioStoreManager sharedInstance] setDeviceRegisteredSettingOnly:BlioDeviceRegisteredStatusUnregistered forSourceID:BlioBookSourceOnlineStore];
    return success;
}

- (BOOL)leaveDomain:(NSString*)token {
    return [self leaveDomainKDRM:token];
}


- (BOOL)reportReading {
    return YES;
}



@end

