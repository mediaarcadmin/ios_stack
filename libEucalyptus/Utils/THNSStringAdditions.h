//
//  THNSStringAdditions.h
//
//  Created by James Montgomerie on 25/04/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <regex.h>
#import "THNSStringSmartQuotes.h"

@interface NSString (THAdditions)

+ (id)stringWithBytes:(const void *)bytes length:(NSUInteger)len encoding:(NSStringEncoding)encoding;
+ (id)stringWithCharacters:(const UniChar *)characters length:(NSUInteger)length backedBy:(id)object;

+ (id)stringWithRegMatch:(regmatch_t *)match fromCString:(const char *)string;
+ (id)stringWithRegMatch:(regmatch_t *)match fromBytes:(const char *)string encoding:(NSStringEncoding)encoding;
+ (id)stringWithByteSize:(long long)byteSize;
- (NSComparisonResult)naturalCompare:(NSString *)aString;
- (NSString *)stringForTitleSorting;
- (NSComparisonResult)titleCompare:(NSString *)aString;

@end
