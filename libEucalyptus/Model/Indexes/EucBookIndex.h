//
//  EucBookIndex.h
//  libEucalyptus
//
//  Created by James Montgomerie on 27/04/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EucFilteredBookPageIndex;
@protocol EucBook;

@interface EucBookIndex : NSObject {
    NSArray *_pageIndexes;
    NSArray *_pageIndexPointSizes;
}

+ (NSUInteger)indexVersion;
+ (NSString *)filenameForPageIndexForPointSize:(NSUInteger)fontSize;
+ (NSString *)constructionFilenameForPageIndexForPointSize:(NSUInteger)fontSize;

+ (void)markBookBundleAsIndexesConstructed:(NSString *)bundlePath;
+ (BOOL)indexesAreConstructedForBookBundle:(NSString *)bundlePath;


+ (EucBookIndex *)bookIndexForBook:(id<EucBook>)book;

@property (nonatomic, readonly) NSArray *pageIndexPointSizes;
@property (nonatomic, readonly) NSArray *pageIndexes;

@end
