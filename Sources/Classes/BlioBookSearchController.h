//
//  BlioBookSearchController.h
//  BlioApp
//
//  Created by matt on 01/06/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioParagraphSource.h"
#import "BlioBookmark.h" // Only needed for debug

@protocol BlioBookSearchDelegate;

@interface BlioBookSearchController : NSObject {
    id<BlioParagraphSource> paragraphSource;
    id<BlioBookSearchDelegate> delegate;
    
    NSString *searchString;
    NSStringCompareOptions searchOptions;
    NSUInteger searchResultsContextCharacters;
    
    id startParagraphID;
    NSUInteger startElementOffset;
    
    id currentParagraphID;
    NSUInteger currentElementOffset;
    NSArray *currentParagraphWords;
    
    BOOL hasLooped;
	BOOL searching;
}

@property (nonatomic, assign) id<BlioParagraphSource> paragraphSource;
@property (nonatomic, assign) id<BlioBookSearchDelegate> delegate;
@property (nonatomic, readonly, getter=isSearching) BOOL searching;
@property (nonatomic, assign) NSUInteger searchResultsContextCharacters;
@property (nonatomic, assign) NSStringCompareOptions searchOptions;

- (id)initWithParagraphSource:(id<BlioParagraphSource>)aParagraphSource;
- (void)findString:(NSString *)string fromBookmarkPoint:(BlioBookmarkPoint *)startBookmarkPoint;
- (void)findNextOccurrence;
- (void)cancel;

@end

@protocol BlioBookSearchDelegate

@optional
- (void)searchController:(BlioBookSearchController *)searchController didFindString:(NSString *)searchString atBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint;
- (void)searchControllerDidReachEndOfBook:(BlioBookSearchController *)searchController;
- (void)searchControllerDidCompleteSearch:(BlioBookSearchController *)searchController;

@end
