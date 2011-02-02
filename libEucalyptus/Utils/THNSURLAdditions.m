//
//  THNSURLAdditions.m
//  libEucalyptus
//
//  Created by James Montgomerie on 14/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "THNSURLAdditions.h"

@implementation NSURL (THAdditions)

- (NSString *)pathRelativeTo:(NSURL *)baseUrl
{
    NSString *baseString = nil;
    if(baseUrl) {
        if(CFURLHasDirectoryPath((CFURLRef)baseUrl)) {
            baseString = [baseUrl absoluteString];
        } else {
            NSURL *baseWithoutFile = (NSURL *)CFURLCreateCopyDeletingLastPathComponent(kCFAllocatorDefault, (CFURLRef)baseUrl);
            if(baseWithoutFile) {
                baseString = [baseWithoutFile absoluteString];
                [baseWithoutFile release];
            } else {
                baseString = [baseUrl absoluteString];
            }
        }
    }
    
    NSString *selfString = [self absoluteString];
    if(baseString) {
        if([selfString hasPrefix:baseString]) {
            NSUInteger baseStringLength = baseString.length;
            if([baseString characterAtIndex:baseStringLength - 1] != '/') {
                ++baseStringLength;
            }
            return [selfString substringFromIndex:baseStringLength];
        }
    }
    return selfString;
}

@end
