//
//  LWCNSStringAdditions.h
//  LibCSSTest
//
//  Created by James Montgomerie on 10/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libwapcaplet/libwapcaplet.h>

static inline NSString *NSStringFromLWCString(lwc_string *lwcString)
{
    return (NSString *)lwcString;
}

lwc_string *lwc_intern_cf_string(CFStringRef str);

static inline lwc_string *lwc_intern_ns_string(NSString *str)
{
    return lwc_intern_cf_string((CFStringRef)str);
}
