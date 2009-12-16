//
//  BookReference.m
//  libEucalyptus
//
//  Created by James Montgomerie on 29/05/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import "EucBookReference.h"
#import "THNSStringAdditions.h"
#import "THRegex.h"
#import "THNSFileManagerAdditions.h"
#import "EucBookPageIndex.h"
#import "EucBookPageIndexPoint.h"
#import <sys/stat.h>

@implementation NSString (BookReferenceAdditions) 

- (NSString *)_singleHumanReadableNameFromLibraryFormattedName
{
    NSString *reformattedString = nil;
    
    NSMutableArray *components = [[self componentsSeparatedByString:@", "] mutableCopy];
    NSMutableArray *reorderedComponents = [[NSMutableArray alloc] initWithCapacity:[components count]];
    
    // Remove the trailing date.
    while([components count] && [[components lastObject] matchPOSIXRegex:@"^(circa[[:space:]]+){0,1}([[:digit:][:punct:]]+([[:space:]]*[bBaA][cCdD]){0,1}){0,1}[[:space:]]*-[[:space:]]*([[:digit:][:punct:]]+([[:space:]]*[bBaA][cCdD]){0,1}){0,1}$"]) {
        [components removeLastObject];
    }
    
    // The ordering of 'Saint' seems mysteriously random in the catalog.
    NSUInteger index = [components indexOfObject:@"Saint"];
    if(index != NSNotFound) {
        [reorderedComponents addObject:@"Saint"];
        [components removeObjectAtIndex:index];
    }
    
    // These titles should aalways be at the start (or after the "Saint").
    if([components count] && [[components lastObject] matchPOSIXRegex:@"^viscount$|^sir$|^baron$|^viscount$|^brother$" flags:REG_EXTENDED | REG_ICASE]) {
        [reorderedComponents addObject:[components lastObject]];
        [components removeLastObject];
    }
    
    // These are all suffixes.
    if([components count] && [[components lastObject] matchPOSIXRegex:@"^jr\\.$|^.*of .+$|^ll\\.?d$|^esq. .*$|^the .+$" flags:REG_EXTENDED | REG_ICASE]) {
        // Move the suffix to the /start/ of the components array so that when 
        // we reverse it into reorderedComponents it will be places at the end.
        [components insertObject:[components lastObject] atIndex:0];
        [components removeLastObject];
    }
    
    // These should be placed before the surname.
    if([components count] && [[components lastObject] matchPOSIXRegex:@"^.* of$|^.* de$|^.* d'$|^.* von$" flags:REG_EXTENDED | REG_ICASE]) {
        // Prepend the first, surname, component in the components array with 
        // the string in question.
        [components replaceObjectAtIndex:0 withObject:[NSString stringWithFormat:@"%@ %@", [components lastObject], [components objectAtIndex:0]]];
        [components removeLastObject];
    }
    
    // Finally, reverse the components into the reorderedComponents array.
    for(NSUInteger componentsCount = [components count]; componentsCount > 0; ) {
        --componentsCount;
        [reorderedComponents addObject:[components objectAtIndex:componentsCount]];
    }
    
    [components release];
    
    // Make a string fromt the reordered components.
    reformattedString = [reorderedComponents componentsJoinedByString:@" "];
    
    [reorderedComponents release];
    
    // There are lots of ways (most commonly "[pseud.]" that a pseudonym is
    // indicated in the catalog.  We find and remove them all.
    THRegex *pseudMatch;
    while((pseudMatch = [reformattedString matchPOSIXRegex:@"^((.*)[[:space:]]){0,1}[^[:space:]]*pseud[^[:space:]]*[[:space:]]*\(.*)$" flags:REG_EXTENDED | REG_ICASE])) {
        NSString *prePseud = [pseudMatch match:2];
        NSString *postPseud = [pseudMatch match:3];
        if(prePseud && postPseud) {
            reformattedString = [prePseud stringByAppendingFormat:@" %@", postPseud];
        } else {
            if(prePseud) {
                reformattedString = prePseud;
            } else {
                reformattedString = postPseud;
            }
        } 
    }
    
    // Also remove any components in brackets (these are usually expansions
    // of initials).
    THRegex *bracketMatch;
    while((bracketMatch = [reformattedString matchPOSIXRegex:@"^((.*)[[:space:]]){0,1}\\([^)]*\\)[[:space:]]*\(.*)$" flags:REG_EXTENDED | REG_ICASE])) {
        NSString *preBracket = [bracketMatch match:2];
        NSString *postBracket= [bracketMatch match:3];
        if(preBracket && postBracket) {
            reformattedString = [preBracket stringByAppendingFormat:@" %@", postBracket];
        } else {
            if(preBracket) {
                reformattedString = preBracket;
            } else {
                reformattedString = postBracket;
            }
        }
    }
    
    // If we've stripped everything, give up and return the initial string,
    // otherwise return our reformatted string.
    return [reformattedString length] ? reformattedString : self;    
}

- (NSString *)humanReadableNameFromLibraryFormattedName
{
    if(self.length == 0) {
        return NSLocalizedString(@"Unknown", @"Human readable string for an unknown author");
    } else if([self rangeOfString:@" / "].location == NSNotFound) {
        return [self _singleHumanReadableNameFromLibraryFormattedName];
    } else {
        return [[[self componentsSeparatedByString:@" / "] valueForKey:@"_singleHumanReadableNameFromLibraryFormattedName"] componentsJoinedByString:@", "];
    }
}

@end

@implementation EucBookReference

@dynamic etextNumber;
@dynamic title;
@dynamic author;

- (NSString *)humanReadableAuthor
{
    NSString *author = self.author;
    return  [(author ? author : @"") humanReadableNameFromLibraryFormattedName];
}

- (NSString *)humanReadableTitle
{
    return [self.title stringWithSmartQuotes];
}


- (NSComparisonResult)compare:(EucBookReference *)other
{
    NSComparisonResult ret;
    ret = [self.title naturalCompare:other.title];
    if(ret == NSOrderedSame) {
        ret = [self.author naturalCompare:other.author];
        if(ret == NSOrderedSame) {
            ret = [[NSString stringWithFormat:@"%ld", (long)(self.etextNumber)] naturalCompare:[NSString stringWithFormat:@"%ld", (long)other.etextNumber]];
        }            
    }
    return ret;
}
 
- (BOOL)isEqual:(id)other;
{
    return [other isKindOfClass:[EucBookReference class]] && self.etextNumber == ((EucBookReference *)other).etextNumber;
}

@end