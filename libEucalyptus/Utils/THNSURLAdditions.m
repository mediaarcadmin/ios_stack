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
    NSString *baseString;
    if(CFURLHasDirectoryPath((CFURLRef)baseUrl)) {
        baseString = [baseUrl absoluteString];
    } else {
        NSURL *baseWithoutFile = (NSURL *)CFURLCreateCopyDeletingLastPathComponent(kCFAllocatorDefault, (CFURLRef)baseUrl);
        baseString = [baseWithoutFile absoluteString];
        [baseWithoutFile release];
    }
    NSString *selfString = [self absoluteString];
    if([selfString hasPrefix:baseString]) {
        NSUInteger baseStringLength = baseString.length;
        if([baseString characterAtIndex:baseStringLength - 1] != '/') {
            ++baseStringLength;
        }
        return [selfString substringFromIndex:baseStringLength];
    }
    return nil;
}

@end
