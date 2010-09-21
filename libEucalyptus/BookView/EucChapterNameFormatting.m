//
//  EucChapterNameFormatting.m
//  libEucalyptus
//
//  Created by James Montgomerie on 09/03/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import "EucChapterNameFormatting.h"
#import "VCTitleCase.h"
#import "THNSStringAdditions.h"
#import "THPair.h"

@implementation NSString (EucChapterNameFormatting)

static NSCharacterSet *sCharsToTrimTo = nil;
static NSCharacterSet *sCharsToTrim = nil;

- (THPair *)_splitAndFormattedChapterNameWantSubName:(BOOL)wantSubName
{
    if(!sCharsToTrimTo) {
        sCharsToTrim = [[NSMutableCharacterSet whitespaceAndNewlineCharacterSet] retain];
        [(NSMutableCharacterSet *)sCharsToTrim formUnionWithCharacterSet:[NSMutableCharacterSet punctuationCharacterSet]];
        [(NSMutableCharacterSet *)sCharsToTrim removeCharactersInString:@"-[{(\"\'“‘”’«"];
        sCharsToTrimTo = [[sCharsToTrim invertedSet] retain];
    }
    
    NSString *mainName = nil;
    NSString *subName = nil;
    
    NSString *lowercaseName = [self lowercaseString];
    NSUInteger prefixType = 0;
    NSUInteger prefixLength = 0;
    if([lowercaseName hasPrefix:@"chapter"]) {
        prefixType = 1;
        prefixLength = 7;
    } else if([lowercaseName hasPrefix:@"book"]) {
        prefixType = 1;
        prefixLength = 4;
    } else if([lowercaseName hasPrefix:@"stave"]) {
        prefixType = 1;
        prefixLength = 5;
    } else if([lowercaseName hasPrefix:@"act"]) {
        prefixType = 1;
        prefixLength = 3; 
	} else if([lowercaseName hasPrefix:@"part"]) {
        prefixType = 1;
        prefixLength = 4; 
	} else if([lowercaseName hasPrefix:@"section"]) {
        prefixType = 1;
        prefixLength = 7;         
	} else if([lowercaseName hasPrefix:@"volume"]) {
        prefixType = 1;
        prefixLength = 6;
    } else if([lowercaseName hasPrefix:@"appendix"]) {
        prefixType = 2;
        prefixLength = 8;
    }
    
    if(prefixType != 0) {
        NSUInteger lowercaseNameLength = lowercaseName.length;
        
        NSRange startOfSecondWordCharacterRange = [lowercaseName rangeOfCharacterFromSet:sCharsToTrimTo
                                                                                 options:0
                                                                                   range:NSMakeRange(prefixLength, lowercaseNameLength - prefixLength)];
        if(startOfSecondWordCharacterRange.location > prefixLength &&
           startOfSecondWordCharacterRange.length > 0) {
            NSRange endOfSecondWordCharacterRange = [lowercaseName rangeOfCharacterFromSet:sCharsToTrim
                                                                                   options:0
                                                                                     range:NSMakeRange(startOfSecondWordCharacterRange.location, lowercaseNameLength - startOfSecondWordCharacterRange.location)];
            if(endOfSecondWordCharacterRange.length > 0) {
                NSRange startOfThirdWordCharacterRange = [lowercaseName rangeOfCharacterFromSet:sCharsToTrimTo
                                                                                        options:0
                                                                                          range:NSMakeRange(endOfSecondWordCharacterRange.location, lowercaseNameLength - endOfSecondWordCharacterRange.location)];
                if(startOfThirdWordCharacterRange.length > 0) {
                    mainName = [[[lowercaseName substringToIndex:endOfSecondWordCharacterRange.location] titlecaseString] stringWithSmartQuotes];
                    if(wantSubName) {
                        subName = [[[lowercaseName substringFromIndex:startOfThirdWordCharacterRange.location] titlecaseString] stringWithSmartQuotes];
                    }
                }
            }
        }
        
    }

    if(!mainName) {
        mainName = [[lowercaseName titlecaseString] stringWithSmartQuotes];   
    }    
    
    return [THPair pairWithFirst:mainName second:subName]; 
}

- (THPair *)splitAndFormattedChapterName
{
    return [self _splitAndFormattedChapterNameWantSubName:YES];
}

- (NSString *)mainChapterName
{
    return [self _splitAndFormattedChapterNameWantSubName:NO].first;
}

@end
