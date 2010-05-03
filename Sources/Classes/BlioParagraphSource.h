//
//  BlioParagraphSource.h
//  BlioApp
//
//  Created by James Montgomerie on 14/04/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BlioBookmarkPoint;
@protocol EucBookContentsTableViewControllerDataSource;

@protocol BlioParagraphSource <NSObject>

@required
- (void)bookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint toParagraphID:(id *)paragraphID wordOffset:(uint32_t *)wordOffset;
- (BlioBookmarkPoint *)bookmarkPointFromParagraphID:(id)paragraphID wordOffset:(uint32_t)wordOffset;

- (NSArray *)wordsForParagraphWithID:(id)paragraphID;

- (id)nextParagraphIdForParagraphWithID:(id)paragraphID;

- (id<EucBookContentsTableViewControllerDataSource>)contentsDataSource; 

- (NSUInteger)pageNumberForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint;
- (BlioBookmarkPoint *)bookmarkPointForPageNumber:(NSUInteger)pageNumber;
- (NSUInteger)pageCount;

@end
