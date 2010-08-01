//
//  NSString+BlioAdditions.m
//  BlioApp
//
//  Created by James Montgomerie on 30/07/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "NSData+MBBase64.h"

@implementation NSString (BlioAdditions)

+ (NSString *)uniqueStringWithBaseString:(NSString *)baseString
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFUUIDBytes uuidBytes = CFUUIDGetUUIDBytes(theUUID);
    NSData *uuidData = [[NSData alloc] initWithBytesNoCopy:&uuidBytes length:sizeof(CFUUIDBytes) freeWhenDone:NO];
    // Base-64 encoding the uuid gives a much smaller representation than 
    // the standard string one.
    NSString *uuidAddition = [uuidData base64Encoding];
    [uuidData release];
    CFRelease(theUUID);
    
    NSMutableString *ret = [NSMutableString string];
    if(baseString) {
        NSUInteger baseStringLength = baseString.length;
        [ret appendString:baseStringLength > 31 ? [baseString substringToIndex:31] : baseString];
        [ret appendString:@"-"];
    }
    [ret appendString:uuidAddition];
    [ret replaceOccurrencesOfString:@"/" withString:@"-" options:0 range:NSMakeRange(0, ret.length)];

    return ret;
}

@end
