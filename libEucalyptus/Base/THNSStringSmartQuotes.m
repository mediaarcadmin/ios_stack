//
//  THNSStringSmartQuotes.m
//  libEucalyptus
//
//  Created by James Montgomerie on 11/08/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "THNSStringSmartQuotes.h"
#import <pthread.h>

@implementation NSString (THNSStringSmartQuotes)

static NSCharacterSet *sStartSet;
static NSCharacterSet *sQuoteSet;

static pthread_once_t s_setup_character_sets_once_control = PTHREAD_ONCE_INIT;
static void setup_character_sets() {
    sStartSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] retain];
    sQuoteSet = [[NSCharacterSet characterSetWithCharactersInString:@"\"'"] retain];
}

#define	kLeftApostrophe  0x2018
#define kRightApostrophe 0x2019
#define kLeftQuote       0x201C
#define kRightQuote      0x201D

- (NSString *)stringWithSmartQuotesWithPreviousCharacter:(UniChar)previousCaracterIn
{
    pthread_once(&s_setup_character_sets_once_control, setup_character_sets);
    
    NSMutableString *ret = nil;
    NSString *searchString = self;
    
    NSRange searchRange = NSMakeRange(0, searchString.length);
    NSRange resultRange;
    while((resultRange = [searchString rangeOfCharacterFromSet:sQuoteSet options:0 range:searchRange]).location != NSNotFound) {
        if(resultRange.length == 1) {
            UniChar theChar = [searchString characterAtIndex:resultRange.location];
            UniChar prevChar = resultRange.location > 0 ? [searchString characterAtIndex:resultRange.location - 1] : previousCaracterIn;
            // From http://www.pensee.com/dunham/smartQuotes.html
            if (prevChar == 0 ||                                            // Beginning of text
                prevChar == '(' || prevChar == '[' || prevChar == '{' ||	// Left thingies
                prevChar == '<' || prevChar == 0x00AB ||                    // More left thingies
                prevChar == 0x3008 || prevChar == 0x300A ||                 // Even more left thingies (we could add more Unicode)
                (prevChar == kLeftQuote && theChar == '\'') ||              // Nest apostrophe inside quote
                (prevChar == kLeftApostrophe && theChar == '"') ||          // Alternate nesting
                [sStartSet characterIsMember:prevChar]                       // Beginning of word/line
                ) {
                theChar = (theChar == '"' ? kLeftQuote : kLeftApostrophe);
            } else {
                theChar = (theChar == '"' ? kRightQuote : kRightApostrophe);
            }
            if(!ret) {
                ret = [[self mutableCopy] autorelease];
                searchString = ret;
            }
            [ret replaceCharactersInRange:resultRange withString:[NSString stringWithCharacters:&theChar length:1]];
            searchRange.location = resultRange.location + resultRange.length;
            searchRange.length = searchString.length - searchRange.location;
        }
    }
    
    return searchString;
}

- (NSString *)stringWithSmartQuotes
{
    return [self stringWithSmartQuotesWithPreviousCharacter:'\0'];
}

@end
