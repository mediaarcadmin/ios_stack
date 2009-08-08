//
//  THRegex.m
//
//  Created by James Montgomerie on 22/05/2008.
//  Copyright 2008 James Montgomerie. All rights reserved.
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
            
            [NSException raise: NSInvalidArgumentException
                        format: @"Error %d compiling regular expression (\"%s\")", err, errorStringLength?errorString:""];

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

+ (id)regexDataWithPOSIXRegex:(NSString *)regexString flags:(int)flags
{
    static NSMutableDictionary *compiledRegexCache = nil;
    
    THRegexData *ret = nil;
    id key = flags == REG_EXTENDED ? [regexString retain] : [[THPair alloc] initWithFirst:regexString second:[NSNumber numberWithInt:flags]];
    @synchronized(self) {
        ret = [compiledRegexCache objectForKey:key];
    }
    if(!ret) {
        ret = [[[THRegexData alloc] initWithPOSIXRegex:regexString flags:flags] autorelease];
        if(ret) {
            @synchronized(self) {
                if(!compiledRegexCache) {
                    compiledRegexCache = [[NSMutableDictionary alloc] init];
                }
                [compiledRegexCache setObject:ret forKey:key];
            }
        }
    }
    [key release];
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
    if(_matches) {
        free(_matches);
    }
    if(_UTF8buffer) {
        free(_UTF8buffer);
    }
    return [super dealloc];
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
        
        [NSException raise: NSInvalidArgumentException
                    format: @"Error %d running regular expression (\"%s\")", err, errorStringLength?errorString:""];
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
            return [[[NSString alloc] initWithBytes:_UTF8buffer + start length:end - start encoding:NSUTF8StringEncoding] autorelease];
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

