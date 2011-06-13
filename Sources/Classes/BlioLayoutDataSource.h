/*
 *  BlioLayoutDataSource.h
 *  BlioApp
 *
 *  Created by matt on 09/07/2010.
 *  Copyright 2010 BitWink. All rights reserved.
 *
 */

#import "KNFBLayoutDataSource.h"

@protocol BlioLayoutDataSource <KNFBLayoutDataSource>

@optional
- (BOOL)hasEnhancedContent;
- (NSString *)enhancedContentRootPath;
- (NSData *)enhancedContentDataAtPath:(NSString *)path;
- (NSURL *)temporaryURLForEnhancedContentVideoAtPath:(NSString *)path;
- (NSArray *)enhancedContentForPage:(NSInteger)page;

@end