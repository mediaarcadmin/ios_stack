//
//  LWCNSStringAdditions.h
//  LibCSSTest
//
//  Created by James Montgomerie on 10/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libwapcaplet/libwapcaplet.h>

@interface NSString (LWCAdditions) 

+ (id)stringWithLWCString:(lwc_string *)lwcString;

@end
