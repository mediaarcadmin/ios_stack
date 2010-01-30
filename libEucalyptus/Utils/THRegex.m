//
//  THRegex.m
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

#import "THRegex.h"
#import "THLog.h"
#import "THPair.h"

@implementation THRegexData

- (id)initWithPOSIXRegex:(NSString *)regexString flags:(int)flags
{
    if((self == [super init])) {
        int err = regcomp(&_regex, [regexString UTF8String], flags);
        if(err != 0) {
            int errorStringLength = regerror(err, &_regex, NULL, 0);
            char errorString[errorStringLength];
            regerror(err, &_regex, errorString, errorStringLength);            
            
            [NSException raise:NSInvalidArgumentException
                        format:@"Error %d compiling regular expression (\"%s\")",
                               err, errorStringLength ? errorString : ""];

            [self dealloc];
            return nil;
        }
    }
    return self;
}
  
- (void)dealloc
{
    regfree(&_regex);
    [super dealloc];
}

- (void)finalize
{
    regfree(&_regex);
    [super finalize];
}

+ (id)regexDataWithPOSIXRegex:(NSString *)regexString flags:(int)flags
{
    THRegexData *ret = nil;
    
#ifndef THREGEX_DONT_CACHE
    static NSMutableDictionary *sCompiledRegexCache = nil;
    id key;
    if(flags == REG_EXTENDED) {
        // This is the most popular form of regex, so we just use the string
        // directly as the cache key, to avoid the performance hit of creating
        // a key.
        key = [regexString retain];
    } else {
        // The unmatched '(' will make this key be an invalid regex,
        // so it's guaranteed not to clash with a 'normal' key, above. 
        key = [[NSString alloc] initWithFormat:@"%@(%d", regexString, flags];
    }
    @synchronized(self) {
        ret = [sCompiledRegexCache objectForKey:key];
    }

    if(!ret) {
#endif
        
        ret = [[[THRegexData alloc] initWithPOSIXRegex:regexString flags:flags] autorelease];

#ifndef THREGEX_DONT_CACHE
        if(ret) {
            @synchronized(self) {
                if(!sCompiledRegexCache) {
                    sCompiledRegexCache = [[NSMutableDictionary alloc] init];
                }
                [sCompiledRegexCache setObject:ret forKey:key];
            }
        }        
    }
    [key release];
#endif
    
    return ret;
}

@end


@implementation THRegex

@synthesize regexData = _regexData;

- (id)initWithPOSIXRegex:(NSString *)regexString flags:(int)flags
{    
    if((self = [super init])) {
        _regexData = [[THRegexData regexDataWithPOSIXRegex:regexString flags:flags] retain];
        if(!_regexData) {
            [self dealloc];
            return nil; 
        }
    }
    return self;
}
 

- (id)initWithPOSIXRegex:(NSString *)regex 
{
    return [self initWithPOSIXRegex:regex flags:REG_EXTENDED];
}

+ (id)regexWithPOSIXRegex:(NSString *)regexString
{
    return [[[self alloc] initWithPOSIXRegex:regexString flags:REG_EXTENDED] autorelease];
}
       
+ (id)regexWithPOSIXRegex:(NSString *)regexString flags:(int)flags
{
    return [[[self alloc] initWithPOSIXRegex:regexString flags:flags] autorelease];
}

- (void)dealloc
{
    [_regexData release];
    free(_matches);
    free(_UTF8buffer);
    
    return [super dealloc];
}

- (void)finalize
{
    free(_matches);
    free(_UTF8buffer);
    [super finalize];
}
    

- (BOOL)matchString:(NSString *)string
{
    regex_t *regex = &(_regexData->_regex);
    size_t matchesCount = regex->re_nsub + 1;
    if(!_matches) {
        _matches = malloc(matchesCount * sizeof(regmatch_t));
    }

    CFIndex stringLength = CFStringGetLength((CFStringRef)string);
    CFIndex bufferLength = CFStringGetMaximumSizeForEncoding(stringLength + 1, kCFStringEncodingUTF8);
    if(_bufferLength < bufferLength) {
        if(_UTF8buffer) {
            free(_UTF8buffer);
        }
        _UTF8buffer = malloc(bufferLength);
        _bufferLength = bufferLength;
    } else {
        bufferLength = _bufferLength;
    }
    CFIndex usefBufLen = 0;
    CFStringGetBytes((CFStringRef)string, 
                     CFRangeMake(0, stringLength), 
                     kCFStringEncodingUTF8, 
                     '?', 
                     false,
                     _UTF8buffer,
                     bufferLength, 
                     &usefBufLen);
    _UTF8buffer[usefBufLen] = '\0';
    int err = regexec(regex, (char *)_UTF8buffer, matchesCount, _matches, 0);
    
    if(err == 0) {
        return YES;
    } else if(err != REG_NOMATCH) {
        int errorStringLength = regerror(err, regex, NULL, 0);
        char errorString[errorStringLength];
        regerror(err, regex, errorString, errorStringLength);            
        
        [NSException raise:NSInvalidArgumentException
                    format:@"Error %d running regular expression (\"%s\")", 
                           err, errorStringLength ? errorString : ""];
    }
    return NO;
}


- (NSString *)match:(NSInteger)index
{
    regmatch_t *match = _matches + index;
    regoff_t start = match->rm_so;
    if(start != -1) {
        regoff_t end = match->rm_eo;
        if(start != end)    {
            // Don't use substringWithRange, because it counts in characters, not
            // bytes.
            return [[[NSString alloc] initWithBytes:_UTF8buffer + start 
                                             length:end - start 
                                           encoding:NSUTF8StringEncoding] autorelease];
        }
    } 
    return nil;
}

@end

@implementation NSString (THRegex)

- (THRegex *)matchPOSIXRegex:(NSString *)regexString
{
    THRegex *regex = [[THRegex alloc] initWithPOSIXRegex:regexString];
    if(regex) {
        if([regex matchString:self]) {
            return [regex autorelease];
        } else {
            [regex release];
        }
    }
    return nil;
}

- (THRegex *)matchPOSIXRegex:(NSString *)regexString flags:(int)flags
{
    THRegex *regex = [[THRegex alloc] initWithPOSIXRegex:regexString flags:flags];
    if(regex) {
        if([regex matchString:self]) {
            return [regex autorelease];
        } else {
            [regex release];
        }
    }
    return nil;
}

- (NSString *)stringByEscapingPOSIXRegexCharacters
{
    NSUInteger length = self.length;
    unichar *characters = malloc(length * sizeof(unichar));
    unichar *escapedCharacters = malloc(2 * length * sizeof(unichar));

    [self getCharacters:characters];
    
    unichar *stopAt = characters + length;
    unichar *escapedCharactersAt = escapedCharacters;
    for(unichar *pCh = characters; pCh < stopAt; ++pCh) {
        switch(*pCh) {
            case '^':
            case '.':
            case '[':
            case ']':
            case '$':
            case '(':
            case ')':
            case '|':
            case '*':
            case '+':
            case '?':
            case '{':
            case '}':
            case '\\':
                *escapedCharactersAt++ = '\\';
            default:
                break;
        }
        
        *escapedCharactersAt++ = *pCh;
    }
    
    NSString *ret = [NSString stringWithCharacters:escapedCharacters
                                            length:escapedCharactersAt - escapedCharacters];
    free(escapedCharacters);
    free(characters);
    return ret;
}

@end

