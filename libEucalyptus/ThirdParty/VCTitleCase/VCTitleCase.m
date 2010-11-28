//
//  VCTitleCase.m
//  Title Case extension for NSString
//
//  Based on titlecase.pl by:
//    John Gruber
//    http://daringfireball.net/
//    10 May 2008
//
//  Cocoa Foundation version by:
//    Marshall Elfstrand
//    http://vengefulcow.com/
//    24 May 2008
//
//  License: http://www.opensource.org/licenses/mit-license.php
//

#import "VCTitleCase.h"

@implementation NSString (VCTitleCase)

- (NSString *)titleCaseString
{
    static NSSet *shortWords = nil;
    static NSMutableCharacterSet *wordStartCharacterSet = nil;
    static NSMutableCharacterSet *wordMiddleCharacterSet = nil;
    static NSCharacterSet *notWordMiddleCharacterSet = nil;
    static NSMutableCharacterSet *wordEndCharacterSet = nil;
    static NSMutableCharacterSet *wordIgnoreCharacterSet = nil;
    static NSMutableCharacterSet *nonNumberCharacterSet = nil;
    static NSCharacterSet *sentenceEndCharacterSet = nil;
    static NSUInteger maxShortWordLength = 0;
    
    // Initialize the list of "short" words that remain lowercase.
    if (!shortWords) {
        shortWords = [[NSSet alloc] initWithObjects:
            @"a", @"an", @"and", @"as", @"at", @"but", @"by", @"en", @"for",
            @"if", @"in", @"of", @"on", @"or", @"the", @"to", @"via",
            @"vs", nil];
        maxShortWordLength = 3;
    }
    
    // Initialize the set of characters allowed at the start of words.
    if (!wordStartCharacterSet) {
        wordStartCharacterSet = [[NSCharacterSet uppercaseLetterCharacterSet] mutableCopy];
        [wordStartCharacterSet formUnionWithCharacterSet:[NSCharacterSet lowercaseLetterCharacterSet]];
    }
    
    // Initialize the set of characters allowed in the middle of words.
    if (!wordMiddleCharacterSet) {
        wordMiddleCharacterSet = [[NSCharacterSet uppercaseLetterCharacterSet] mutableCopy];
        [wordMiddleCharacterSet formUnionWithCharacterSet:[NSCharacterSet lowercaseLetterCharacterSet]];
        [wordMiddleCharacterSet addCharactersInString:@".&'’"];
    }
    
    if (!notWordMiddleCharacterSet) {
        notWordMiddleCharacterSet = [[wordMiddleCharacterSet invertedSet] retain];
    }
    
    // Initialize the set of characters allowed at the end of words.
    if (!wordEndCharacterSet) wordEndCharacterSet = wordStartCharacterSet;
    
    // Initialize the set of characters that cause a word to be ignored
    // when they appear in the middle.
    if (!wordIgnoreCharacterSet) {
        wordIgnoreCharacterSet = [[NSCharacterSet uppercaseLetterCharacterSet] mutableCopy];
        [wordIgnoreCharacterSet addCharactersInString:@"."];
    }
    
    // Initialize the set of non-numeric (including small Roman numerals) characters.
    if (!nonNumberCharacterSet) {
        nonNumberCharacterSet = [[NSCharacterSet decimalDigitCharacterSet] mutableCopy];
        [nonNumberCharacterSet addCharactersInString:@"ivxlc"];
        [nonNumberCharacterSet invert];
    }
    
    // Initialize the set of non-numeric (including small Roman numerals) characters.
    if (!sentenceEndCharacterSet) {
        sentenceEndCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@".?!:;"] retain];
    }

    // Create a local autorelease pool for the temporary objects we're making.
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // Create a mutable copy of the string that we can modify in-place.
    NSMutableString *newString = [self mutableCopy];
    
    // Begin scanning for words.
    NSRange currentRange = NSMakeRange(0, 0); // Range of word located by scanner
    NSString *word = nil;                     // Extracted word
    BOOL isFirstWord = YES;                   // To determine whether to capitalize small word
    
    NSUInteger scanLocation = 0;
    NSUInteger myLength = self.length;
    while (scanLocation < myLength) {
        if ([sentenceEndCharacterSet characterIsMember:[self characterAtIndex:scanLocation]]) {
            isFirstWord = YES;
        }
        
        // Locate the beginning of the next word.
        NSRange scanRange = NSMakeRange(scanLocation, myLength - scanLocation);
        scanLocation = [self rangeOfCharacterFromSet:wordStartCharacterSet options:0 range:scanRange].location;
        
        if (scanLocation == NSNotFound) continue;  // No more words
        currentRange.location = scanLocation;

        // Locate the potential end of the word.
        scanRange = NSMakeRange(scanLocation, myLength - scanLocation);
        scanLocation = [self rangeOfCharacterFromSet:notWordMiddleCharacterSet options:0 range:scanRange].location;

        if (scanLocation == NSNotFound) {
            scanLocation = myLength;
        }
        currentRange.length = scanLocation - currentRange.location;
        
        // Back off the word until it ends with a valid character.
        unichar lastCharacter = [self characterAtIndex:(NSMaxRange(currentRange) - 1)];
        while (![wordEndCharacterSet characterIsMember:lastCharacter]) {
            --scanLocation;
            currentRange.length -= 1;
            lastCharacter = [self characterAtIndex:(NSMaxRange(currentRange) - 1)];
        }

        // We have now located a word.
        word = [self substringWithRange:currentRange];
        BOOL wordWouldCountAsFirstWord = YES;
        
        // Check to see if the word needs to be capitalized.
        // Words that have dots in the middle or that already contain
        // capitalized letters in the middle (e.g. "iTunes") are ignored.
        NSRange ignoreTriggerRange = [self
                    rangeOfCharacterFromSet:wordIgnoreCharacterSet
                                    options:NSLiteralSearch
                                      range:NSMakeRange(currentRange.location + 1, currentRange.length - 1)
        ];
        if (ignoreTriggerRange.location == NSNotFound) {
            if ([word rangeOfString:@"&"].location != NSNotFound) {
                // Uppercase words that contain ampersands.
                [newString replaceCharactersInRange:currentRange
                                         withString:[word uppercaseString]];
            } else if ((!isFirstWord) && word.length <= maxShortWordLength && [shortWords containsObject:[word lowercaseString]]) {
                // Lowercase small words.
                [newString replaceCharactersInRange:currentRange
                                         withString:[word lowercaseString]];
            } else if([word rangeOfCharacterFromSet:nonNumberCharacterSet].location == NSNotFound) {
                // Uppercase roman numerals.
                [newString replaceCharactersInRange:currentRange
                                         withString:[word uppercaseString]];
                wordWouldCountAsFirstWord = NO;
            } else {
                // Capitalize word.
                [newString replaceCharactersInRange:currentRange
                                         withString:[word capitalizedString]];
            }
        }

        if(isFirstWord && wordWouldCountAsFirstWord) {
            isFirstWord = NO;
        }
    }

    // Make sure the last word is capitalized, even if it is a small word.
    if (word && word.length <= maxShortWordLength) {
        if([shortWords containsObject:[word lowercaseString]]) {
            [newString replaceCharactersInRange:currentRange
                                     withString:[word capitalizedString]];
        }
    }
    
    // Release our temporary objects.
    [pool drain];

    return [newString autorelease];
}

@end
