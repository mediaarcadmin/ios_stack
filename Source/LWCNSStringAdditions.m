//
//  LWCNSStringAdditions.m
//  LibCSSTest
//
//  Created by James Montgomerie on 10/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "LWCNSStringAdditions.h"

@implementation NSString (LWCAdditions)

+ (id)stringWithLWCString:(lwc_string *)lwcString
{
    return [[[NSString alloc] initWithBytes:lwc_string_data(lwcString) 
                                     length:lwc_string_length(lwcString) 
                                   encoding:NSUTF8StringEncoding] autorelease];
}

- (lwc_string *)lwcStringInContext:(lwc_context *)context
{
    lwc_string *ret;
    const char *utf8String = [self UTF8String];
    lwc_context_intern(context, utf8String, strlen(utf8String), &ret);
    return ret;
}

@end
