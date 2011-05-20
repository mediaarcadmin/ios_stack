//
//  BlioParagraphSource.h
//  BlioApp
//
//  Created by James Montgomerie on 14/04/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "KNFBParagraphSource.h"

@class THPair, BlioBookmarkPoint;

@protocol BlioParagraphSource <KNFBParagraphSource>

- (NSArray *)sectionUuids;
- (NSUInteger)levelForSectionUuid:(NSString *)sectionUuid;
- (THPair *)presentationNameAndSubTitleForSectionUuid:(NSString *)sectionUuid;

- (BlioBookmarkPoint *)bookmarkPointForSectionUuid:(NSString *)sectionUuid;
- (NSString *)sectionUuidForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint;

- (BlioBookmarkPoint *)estimatedBookmarkPointForPercentage:(float)percentage;
- (float)estimatedPercentageForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint;

@end
