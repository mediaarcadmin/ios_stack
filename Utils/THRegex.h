//
//  THRegex.h
//  http://www.blog.montgomerie.net/using-the-mac-or-iphones-built-in-regex
//
//  Created by James Montgomerie on 22/05/2008.
//  jamie@th.ingsmadeoutofotherthin.gs
//  http://www.blog.montgomerie.net/
//
//  Copyright 2008-2009 Things Made Out Of Other Things Ltd.
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice, 
//    this list of conditions and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//  * Neither the name of the Things Made Out Of Other Things Ltd., nor the
//    names of its contributors may be used to endorse or promote products 
//    derived from this software without specific prior written permission.
// 
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//

#import <Foundation/Foundation.h>
#import <regex.h>

@class THRegexData;

/// POSIX regular expression class.
///
/// Can be used to match against strings, and provide matched substrings for
/// subexpressions in the last string matched against.
///
/// The implementation will, by default, cache all regexes compiled with it
/// (the POSIX regex compiler is very slow).  If you don't want this behavior
/// define at compile time (e.g. with a "-DTHREGEX_DONT_CACHE" flag to GCC).
///
/// Note that POSIX regular expressions work on <b>BYTES, NOT CHARACTERS</b>.
/// This class uses UTF-8 representations for matching.  Understand what this
/// means before you use it.
/// If you're not aware of the byte/character distinction, you may end up 
/// blindly chopping up characters, or non-composed pairs.
/// Also note that this means that predefined character classes 
/// (e.g. [[:LOWER:]] etc) only cover Roman ASCII characters.
/// 
@interface THRegex : NSObject {
    THRegexData *_regexData;
    regmatch_t *_matches;
    UInt8 *_UTF8buffer;
    size_t _bufferLength;
}

/// Implementation detail - you shouldn't need to use this. 
@property (nonatomic, readonly) THRegexData *regexData;

/// Inits a regular expression from a POSIX regex string, with REG_EXTENDED set.
/// @param regexString a POSIX regex string (see 'man reformat', 'man regex').
- (id)initWithPOSIXRegex:(NSString *)regexString;

/// Inits a regular expression from a POSIX regex string, allows user
/// to specify flags (see 'man regex').  You probably want at least 
/// REG_EXTENDED, and perhaps REG_ICASE.
/// @param regexString a POSIX regex string (see 'man reformat', 'man regex').
/// @param flags POSIX regex flags (see 'man reformat', 'man regex').
/// @see initWithPOSIXRegex:
- (id)initWithPOSIXRegex:(NSString *)regexString flags:(int)flags;


/// Returns a regular expression initialized from a POSIX regex string
/// with REG_EXTENDED set.
/// @param regexString a POSIX regex string (see 'man reformat', 'man regex').
/// @see THRegex
/// @see initWithPOSIXRegex:
+ (id)regexWithPOSIXRegex:(NSString *)regexString;

/// Inits a regular expression from a POSIX regex string, allows user
/// to specify flags (see 'man regex'). 
/// @param regexString a POSIX regex string (see 'man reformat', 'man regex').
/// @param flags POSIX regex flags (see 'man reformat', 'man regex').
/// @see THRegex
/// @see initWithPOSIXRegex:flags:
+ (id)regexWithPOSIXRegex:(NSString *)regexString flags:(int)flags;


/// Matches a string against this regular expression.
/// @param string the string to match. 
- (BOOL)matchString:(NSString *)string;

/// Return the last match to the specified subexpression.
/// @param index the index of the required match. Note that match 0 is the 
///   entire regex, match 1 is the first parenthesized subexpression etc. (see
///   'man regex').
- (NSString *)match:(NSInteger)index;

@end


@interface NSString (THRegex)

/// Matches this string against a POSIX regex, assuming REG_EXTENDED flags.
/// @return a valid THRegex object on success, nil on failure to match. 
/// @param regexString a POSIX regex (see 'man reformat', 'man regex').
/// @see -[THRegex initWithPOSIXRegex:]
- (THRegex *)matchPOSIXRegex:(NSString *)regexString;

/// Matches this string against a POSIX regex.
/// @return a valid THRegex object on success, nil on failure to match. 
/// @param regexString a POSIX regex (see 'man reformat', 'man regex').
/// @param flags POSIX regex flags (see 'man reformat', 'man regex').
/// @see -[THRegex initWithPOSIXRegex:flags:]
- (THRegex *)matchPOSIXRegex:(NSString *)regexString flags:(int)flags;

/// Returns a string identical to this string, but with characters treated as 
/// special by POSIX regexes (see 'man reformat' escaped with prepended '\'
/// characters.
- (NSString *)stringByEscapingPOSIXRegexCharacters;

@end


/// Implementation detail - you shouldn't need to use this. 
@interface THRegexData : NSObject {
@public
    regex_t _regex;
}

+ (id)regexDataWithPOSIXRegex:(NSString *)regexString flags:(int)flags;

@end

#define NUMBER_RE @"([ivxlc]+|[[:digit:]]+|(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundred|thousand|and|[-]|[[:space:]])*(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundred|thousand)+)"
#define NUMBER_RE_SUBEXPRESSION_COUNT 3