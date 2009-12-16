//
//  THRegex.h
//
//  Created by James Montgomerie on 22/05/2008.
//  Copyright 2008-2009 James Montgomerie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <regex.h>

@class THRegexData;

@interface THRegex : NSObject {
    THRegexData *_regexData;
    regmatch_t *_matches;
    UInt8 *_UTF8buffer;
    size_t _bufferLength;
}

@property (nonatomic, readonly) THRegexData *regexData;

- (id)initWithPOSIXRegex:(NSString *)regexString;
- (id)initWithPOSIXRegex:(NSString *)regexString flags:(int)flags;

+ (id)regexWithPOSIXRegex:(NSString *)regexString;
+ (id)regexWithPOSIXRegex:(NSString *)regexString flags:(int)flags;

- (BOOL)matchString:(NSString *)string;

- (NSString *)match:(NSInteger)index;

@end


@interface NSString (THRegex)

- (THRegex *)matchPOSIXRegex:(NSString *)regexString;
- (THRegex *)matchPOSIXRegex:(NSString *)regexString flags:(int)flags;

- (NSString *)stringByEscapingPOSIXRegexCharacters;

@end

@interface THRegexData : NSObject {
@public
    regex_t _regex;
}

+ (id)regexDataWithPOSIXRegex:(NSString *)regexString flags:(int)flags;

@end

#define NUMBER_RE @"([ivxlc]+|[[:digit:]]+|(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundred|thousand|and|[-]|[[:space:]])*(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundred|thousand)+)"
#define NUMBER_RE_SUBEXPRESSION_COUNT 3