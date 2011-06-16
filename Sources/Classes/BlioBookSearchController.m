//
//  BlioBookSearchController.m
//  BlioApp
//
//  Created by matt on 01/06/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioBookSearchController.h"
#import "BlioBookManager.h"
#import "UIDevice+BlioAdditions.h"

@interface BlioBookSearchController()

@property (nonatomic, retain) NSManagedObjectID *bookID;
@property (nonatomic, retain) id<BlioParagraphSource> paragraphSource;
@property (nonatomic, getter=isSearching) BOOL searching;
@property (nonatomic, retain) NSString *searchString;
@property (nonatomic, retain) BlioBookmarkPoint *startBookmarkPoint;
@property (nonatomic, retain) id startParagraphID;
@property (nonatomic, assign) NSUInteger startElementOffset;
@property (nonatomic, retain) id currentParagraphID;
@property (nonatomic, assign) NSUInteger currentCharacterOffset;
@property (nonatomic, retain) NSArray *currentParagraphWords;
@property (nonatomic, assign) BOOL hasWrapped;

@end

@implementation BlioBookSearchController

@synthesize bookID, paragraphSource, delegate, searchString, searching, searchOptions, maxPrefixAndMatchLength, maxSuffixLength, startBookmarkPoint, startParagraphID, startElementOffset, currentParagraphID, currentCharacterOffset, currentParagraphWords, hasWrapped;

- (void)dealloc {
    [self cancel];
    if(self.paragraphSource) {
        self.paragraphSource = nil;
        [[BlioBookManager sharedBookManager] checkInParagraphSourceForBookWithID:self.bookID];
    }
    self.delegate = nil;
    self.searchString = nil;
    self.startBookmarkPoint = nil;
    self.startParagraphID = nil;
    self.currentParagraphID = nil;
    self.currentParagraphWords = nil;
    self.bookID = nil;
    [super dealloc];
}

- (id)initWithBookID:(NSManagedObjectID *)aBookID {
    if ((self = [super init])) {
        self.bookID = aBookID;
        self.paragraphSource = [[BlioBookManager sharedBookManager] checkOutParagraphSourceForBookWithID:aBookID];
        self.searchOptions = NSCaseInsensitiveSearch;
        searchInterval = [[UIDevice currentDevice] blioDeviceSearchInterval];
    }
    return self;
}

- (BOOL)findString:(NSString *)string fromBookmarkPoint:(BlioBookmarkPoint *)myStartBookmarkPoint {
    if ([string rangeOfCharacterFromSet:[[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet]].location == NSNotFound) {
        return NO;
    }
    self.searchString = string;
    self.hasWrapped = NO;
    
    if (!myStartBookmarkPoint) { 
        myStartBookmarkPoint = [[[BlioBookmarkPoint alloc] init] autorelease];
        myStartBookmarkPoint.layoutPage = 1;
    }
    
    self.startBookmarkPoint = myStartBookmarkPoint;
    
    NSIndexPath *paragraphID = nil;
    uint32_t wordOffset = 0;
    [self.paragraphSource bookmarkPoint:myStartBookmarkPoint toParagraphID:&paragraphID wordOffset:&wordOffset];
    
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
    self.currentCharacterOffset = elementOffset;
    
    self.startParagraphID = self.currentParagraphID;
    self.startElementOffset = self.currentCharacterOffset;
    
    [self findNextOccurrence];
    
    return YES;
}

- (void)searchStopped {
    self.searching = NO;
}

- (void)searchCompleted {
    [self searchStopped];
    
    if ([(NSObject *)self.delegate respondsToSelector:@selector(searchControllerDidCompleteSearch:)])
        [self.delegate searchControllerDidCompleteSearch:self];
}

- (void)searchReachedEndOfBook {
    [self searchStopped];
    
    BlioBookmarkPoint *startofBookBookmarkPoint = [[[BlioBookmarkPoint alloc] init] autorelease];
    startofBookBookmarkPoint.layoutPage = 1;
    
    NSIndexPath *paragraphID = nil;
    uint32_t wordOffset = 0;
    [self.paragraphSource bookmarkPoint:startofBookBookmarkPoint toParagraphID:&paragraphID wordOffset:&wordOffset];
    
    self.currentParagraphID = paragraphID;
    self.currentParagraphWords = [self.paragraphSource wordsForParagraphWithID:self.currentParagraphID];
    self.currentCharacterOffset = 0;

    self.hasWrapped = YES;
    
    if ([(NSObject *)self.delegate respondsToSelector:@selector(searchControllerDidReachEndOfBook:)])
        [self.delegate searchControllerDidReachEndOfBook:self];
}

- (void)cancel {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(findNextOccurrence) object:nil];
    [self searchStopped];
}

- (void)findNextOccurrence {
    
    self.searching = YES;
    
    // TODO - confirm that paragraphIDs observe the comparison correctly
    if (self.hasWrapped) {
        BlioBookmarkPoint *currentBookmarkPoint = [self.paragraphSource bookmarkPointFromParagraphID:self.currentParagraphID wordOffset:0];
        if ([startBookmarkPoint compare:currentBookmarkPoint] == NSOrderedAscending) {
                [self searchCompleted];
                return;
            }
    }
    
    NSString *currentParagraphString = [self.currentParagraphWords componentsJoinedByString:@" "];
    
    NSRange foundRange = NSMakeRange(NSNotFound, 0);
    NSInteger searchLength = [currentParagraphString length] - 1 - self.currentCharacterOffset;
    
    if (searchLength > 0) {
        NSRange searchRange = NSMakeRange(self.currentCharacterOffset, searchLength);
        foundRange = [currentParagraphString rangeOfString:self.searchString options:self.searchOptions range:searchRange];
//        NSLog(@"%@", [currentParagraphString substringWithRange:searchRange]);
    }
    
    if (foundRange.location != NSNotFound) {
        self.currentCharacterOffset = foundRange.location + foundRange.length;
        
        NSUInteger characterOffset = 0;
        NSUInteger beginningWordOffset = 0;
        NSUInteger endWordOffset = 0;
        // Although we calculate the beginning & end character offsets for teh range they are 
        // discarded because BlioBookmarkRange does not store charcters just element offsets (to handle hyphenation)
        NSUInteger beginningCharacterOffset = NSNotFound;
        NSUInteger endCharacterOffset = NSNotFound;
        NSString *prefix = @"";
        
        for (NSString *word in self.currentParagraphWords) {
            NSUInteger endOfWord = characterOffset + [word length];
            if (endOfWord > foundRange.location) {
                if (beginningCharacterOffset == NSNotFound) {
                    beginningCharacterOffset = foundRange.location - characterOffset;
                    prefix = [word substringWithRange:NSMakeRange(0, beginningCharacterOffset)];
                }
                
                if (endOfWord >= currentCharacterOffset) {
                    endCharacterOffset = currentCharacterOffset - characterOffset - 1;
                    break;
                }
                
                characterOffset += [word length] + 1;
                endWordOffset++;
            } else {
                characterOffset += [word length] + 1;
                beginningWordOffset++;
                endWordOffset++;
            }
        }
        
        NSString *matchString = [currentParagraphString substringWithRange:foundRange];
        NSUInteger endOfMatchOffset = foundRange.location + foundRange.length;
        NSString *suffix = [currentParagraphString substringWithRange:NSMakeRange(endOfMatchOffset, MIN(self.maxSuffixLength, [currentParagraphString length] - 1 - endOfMatchOffset))];
        
        NSInteger prefixLength = self.maxPrefixAndMatchLength - foundRange.length;
        
        if (prefixLength > 0) {
            NSArray *prefixWords = [self.currentParagraphWords subarrayWithRange:NSMakeRange(0, beginningWordOffset)] ;
            NSEnumerator *reversedWords = [prefixWords reverseObjectEnumerator];
            
            for (NSString *prefixWord in reversedWords) {
                if (([prefix length] + [prefixWord length]) < prefixLength)
                    prefix = [NSString stringWithFormat:@"%@ %@", prefixWord, prefix];
                else
                    break;
            }
        }
        
        BlioBookmarkRange *foundBookmarkRange = nil;
        if ((beginningCharacterOffset != NSNotFound) && (endCharacterOffset != NSNotFound)) {
            BlioBookmarkPoint *foundBookmarkBeginningPoint = [self.paragraphSource bookmarkPointFromParagraphID:self.currentParagraphID wordOffset:beginningWordOffset];
            foundBookmarkBeginningPoint.elementOffset = 0; // see note about character offsets above
            BlioBookmarkPoint *foundBookmarkEndPoint = [self.paragraphSource bookmarkPointFromParagraphID:self.currentParagraphID wordOffset:endWordOffset];
            foundBookmarkEndPoint.elementOffset = 0; // see note about character offsets above
            foundBookmarkRange = [[[BlioBookmarkRange alloc] init] autorelease];
            foundBookmarkRange.startPoint = foundBookmarkBeginningPoint;
            foundBookmarkRange.endPoint = foundBookmarkEndPoint;
        }
        
        [self searchStopped];
        
        if ([(NSObject *)self.delegate respondsToSelector:@selector(searchController:didFindString:atBookmarkRange:withPrefix:withSuffix:)])
            [self.delegate searchController:self didFindString:matchString atBookmarkRange:foundBookmarkRange withPrefix:prefix withSuffix:suffix];
        
    } else {
        self.currentParagraphID = [self.paragraphSource nextParagraphIdForParagraphWithID:self.currentParagraphID];
        
        if (!self.currentParagraphID) {
            if (self.hasWrapped) {
                [self searchCompleted];
                return;
            } else {
                [self searchReachedEndOfBook];
                return;
            }
        } else {
            self.currentParagraphWords = [self.paragraphSource wordsForParagraphWithID:self.currentParagraphID];
            self.currentCharacterOffset = 0;
            
            if (self.hasWrapped) {
                BlioBookmarkPoint *currentBookmarkPoint = [self.paragraphSource bookmarkPointFromParagraphID:self.currentParagraphID wordOffset:0];
                if ([startBookmarkPoint compare:currentBookmarkPoint] == NSOrderedAscending) {
                    [self searchCompleted];
                    return;
                } 
            }
        
            //BlioBookmarkPoint *debugBookmarkPoint = [self.paragraphSource bookmarkPointFromParagraphID:self.currentParagraphID wordOffset:0];
            //NSLog(@"Page %d paragraph %d has %d words", [debugBookmarkPoint layoutPage], [debugBookmarkPoint blockOffset], [self.currentParagraphWords count]);
            // Need to always allow at least a 0.01f delay before finding teh next occureence otherwise the UI freezes
            [self performSelector:@selector(findNextOccurrence) withObject:nil afterDelay:searchInterval + 0.01f];
        }
    }
}

@end
