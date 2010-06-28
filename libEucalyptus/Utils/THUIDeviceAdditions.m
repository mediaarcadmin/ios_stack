//
//  THUIDeviceAdditions.m
//  Eucalyptus
//
//  Created by James Montgomerie on 26/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "THUIDeviceAdditions.h"
#import <CommonCrypto/CommonDigest.h>

@implementation UIDevice (THUIDeviceAdditions)

- (uint32_t)nonidentifiableUniqueIdentifier
{
    uint32_t ret = 0;
    NSString *uniqueIdentifier = [self uniqueIdentifier];
    
    if(uniqueIdentifier) {
        unsigned char digest[16];
        const char *string = [uniqueIdentifier UTF8String];
        CC_MD5(string, strlen(string), digest);

        uint32_t *bigResult = (uint32_t *)digest;
        for(int i = 1; i < 4; ++i) {
            ret ^= bigResult[i];
        }
    }
    
    return ret;
}

- (NSComparisonResult)compareSystemVersion:(NSString *)otherVersion
{
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    return [currSysVer compare:otherVersion options:NSNumericSearch];       
}

@end
