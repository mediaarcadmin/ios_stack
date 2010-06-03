//
//  BlioBookSearchController.m
//  BlioApp
//
//  Created by matt on 01/06/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioBookSearchController.h"

@interface BlioBookSearchController()

@property (nonatomic, getter=isSearching) BOOL searching;
@property (nonatomic, retain) NSString *searchString;
@property (nonatomic, retain) id currentParagraphID;
@property (nonatomic, assign) NSUInteger currentElementOffset;
@property (nonatomic, retain) NSArray *currentParagraphWords;

@end

@implementation BlioBookSearchController

@synthesize paragraphSource, delegate, searchString, searching, searchOptions, searchResultsContextCharacters, currentParagraphID, currentElementOffset, currentParagraphWords;

- (void)dealloc {
    [self cancel];
    self.paragraphSource = nil;
    self.delegate = nil;
    self.searchString = nil;
    self.currentParagraphID = nil;
    self.currentParagraphWords = nil;
    [super dealloc];
}

- (id)initWithParagraphSource:(id<BlioParagraphSource>)aParagraphSource {
    if ((self = [super init])) {
        self.paragraphSource = aParagraphSource;
        self.searchOptions = NSCaseInsensitiveSearch;
    }
    return self;
}

- (void)findString:(NSString *)string fromBookmarkPoint:(BlioBookmarkPoint *)startBookmarkPoint {
    self.searchString = string;
    
    if (!startBookmarkPoint) startBookmarkPoint = [self.paragraphSource bookmarkPointForPageNumber:1];
    
    NSIndexPath *paragraphID = nil;
    uint32_t wordOffset = 0;
    [self.paragraphSource bookmarkPoint:startBookmarkPoint toParagraphID:&paragraphID wordOffset:&wordOffset];
    
    self.currentParagraphID = paragraphID;
    self.currentParagraphWords = [self.paragraphSource wordsForParagraphWithID:self.currentParagraphID];
    
    NSUInteger elementOffset = 0;
    for (int i = 0; i < [self.currentParagraphWords count]; i++) {
        if (i < wordOffset) {
            elementOffset += [[self.currentParagraphWords objectAtIndex:i] length] + 1;
        } else {
            break;
        }
    }
    self.currentElementOffset = elementOffset;
    
    [self findNextOccurrence];
}

- (void)searchEnded {
    self.searching = NO;
    NSLog(@"Search ended");
}

- (void)searchReachedEndOfBook {
    if ([(NSObject *)self.delegate respondsToSelector:@selector(searchController:didFindString:atBookmarkPoint:)])
        [self.delegate searchController:self didFindString:self.searchString atBookmarkPoint:nil];
    
    [self searchEnded];
}

- (void)cancel {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(findNextOccurrence) object:nil];
    [self searchEnded];
}

- (void)findNextOccurrence {
        
    self.searching = YES;
    
    NSString *currentParagraphString = [self.currentParagraphWords componentsJoinedByString:@" "];
    
    NSRange foundRange = NSMakeRange(NSNotFound, 0);
    NSRange searchRange = NSMakeRange(self.currentElementOffset, [currentParagraphString length] - 1 - self.currentElementOffset);
    
    if (searchRange.length > 0)
        foundRange = [currentParagraphString rangeOfString:self.searchString options:self.searchOptions range:searchRange];
        
        if (foundRange.location != NSNotFound) {
            self.currentElementOffset = foundRange.location + 1;
            
            NSUInteger characterOffset = 0;
            NSUInteger wordOffset = 0;
            NSUInteger elementOffset = NSNotFound;
            
            for (NSString *word in self.currentParagraphWords) {
                if ((characterOffset + [word length]) > foundRange.location) {
                    elementOffset = foundRange.location - characterOffset;
                    break;
                } else {
                    characterOffset += [word length] + 1;
                    wordOffset++;
                }
            }
            
            BlioBookmarkPoint *foundBookmarkPoint = nil;
            if (elementOffset != NSNotFound) {
                foundBookmarkPoint = [self.paragraphSource bookmarkPointFromParagraphID:self.currentParagraphID wordOffset:wordOffset];
                foundBookmarkPoint.elementOffset = elementOffset;
            }
            
            [self searchEnded];
            
            if ([(NSObject *)self.delegate respondsToSelector:@selector(searchController:didFindString:atBookmarkPoint:)])
                [self.delegate searchController:self didFindString:self.searchString atBookmarkPoint:foundBookmarkPoint];
            
        } else {
            self.currentParagraphID = [self.paragraphSource nextParagraphIdForParagraphWithID:self.currentParagraphID];
            
            if (!self.currentParagraphID) {
                [self searchReachedEndOfBook];
            } else {
                self.currentParagraphWords = [self.paragraphSource wordsForParagraphWithID:self.currentParagraphID];
                self.currentElementOffset = 0;
                
                BlioBookmarkPoint *debugBookmarkPoint = [self.paragraphSource bookmarkPointFromParagraphID:self.currentParagraphID wordOffset:0];
                NSLog(@"Page %d paragraph %d has %d words", [debugBookmarkPoint layoutPage], [debugBookmarkPoint blockOffset], [self.currentParagraphWords count]);

                [self performSelector:@selector(findNextOccurrence) withObject:nil afterDelay:0.01f];
            }
        }
}

@end
