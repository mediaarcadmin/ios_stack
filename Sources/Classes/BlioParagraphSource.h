//
//  BlioParagraphSource.h
//  BlioApp
//
//  Created by James Montgomerie on 14/04/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BlioBookmarkPoint;

@protocol BlioParagraphSource <NSObject>

- (void)bookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint toParagraphID:(id *)paragraphID wordOffset:(uint32_t *)wordOffset;
- (BlioBookmarkPoint *)bookmarkPointFromParagraphID:(id)paragraphID wordOffset:(uint32_t)wordOffset;

- (NSArray *)wordsForParagraphWithID:(id)paragraphID;

- (id)nextParagraphIdForParagraphWithID:(id)paragraphID;

@end