//
//  BlioBookSearchController.h
//  BlioApp
//
//  Created by matt on 01/06/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BlioParagraphSource.h"
#import "BlioBookmark.h" // Only needed for debug

@protocol BlioBookSearchDelegate;

@interface BlioBookSearchController : NSObject {
    NSManagedObjectID *bookID;
    
    id<BlioParagraphSource> paragraphSource;
    id<BlioBookSearchDelegate> delegate;
    
    NSString *searchString;
    NSStringCompareOptions searchOptions;
    NSUInteger maxPrefixAndMatchLength;
    NSUInteger maxSuffixLength;
    
    id startParagraphID;
    NSUInteger startElementOffset;
    
    id currentParagraphID;
    NSUInteger currentCharacterOffset;
    NSArray *currentParagraphWords;
    
    BlioBookmarkPoint *startBookmarkPoint;
    
    BOOL hasWrapped;
	BOOL searching;    
    
    NSTimeInterval searchInterval;
}

@property (nonatomic, assign) id<BlioBookSearchDelegate> delegate;
@property (nonatomic, readonly, getter=isSearching) BOOL searching;
@property (nonatomic, assign) NSUInteger maxPrefixAndMatchLength;
@property (nonatomic, assign) NSUInteger maxSuffixLength;
@property (nonatomic, assign) NSStringCompareOptions searchOptions;
@property (nonatomic, readonly) BOOL hasWrapped;

- (id)initWithBookID:(NSManagedObjectID *)aBookID;
- (BOOL)findString:(NSString *)string fromBookmarkPoint:(BlioBookmarkPoint *)startBookmarkPoint;
- (void)findNextOccurrence;
- (void)cancel;

@end

@protocol BlioBookSearchDelegate

@optional
- (void)searchController:(BlioBookSearchController *)searchController didFindString:(NSString *)searchString atBookmarkRange:(BlioBookmarkRange *)bookmarkRange withPrefix:(NSString *)prefix withSuffix:(NSString *)suffix;
- (void)searchControllerDidReachEndOfBook:(BlioBookSearchController *)searchController;
- (void)searchControllerDidCompleteSearch:(BlioBookSearchController *)searchController;

@end
