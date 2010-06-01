//
//  EucBookIndex.h
//  libEucalyptus
//
//  Created by James Montgomerie on 27/04/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EucFilteredBookPageIndex;
@protocol EucBook;

@interface EucBookIndex : NSObject {
    NSString *_indexesPath;
    CGSize _pageSize;
    NSArray *_pageIndexes;
    NSArray *_pageIndexPointSizes;
}

+ (NSUInteger)indexVersion;
+ (NSString *)filenameForPageIndexForFont:(NSString *)font
                                 pageSize:(CGSize)pageSize
                                 fontSize:(NSUInteger)fontSize;
+ (NSString *)constructionFilenameForPageIndexForFont:(NSString *)font
                                             pageSize:(CGSize)pageSize
                                             fontSize:(NSUInteger)fontSize;

+ (void)markBookBundleAsIndexesConstructed:(NSString *)bundlePath;
+ (BOOL)indexesAreConstructedForBookBundle:(NSString *)bundlePath;

+ (EucBookIndex *)bookIndexForBook:(id<EucBook>)book;


@property (nonatomic, assign) CGSize pageSize;
@property (nonatomic, readonly) NSArray *pageIndexPointSizes;
@property (nonatomic, readonly) NSArray *pageIndexes;

@end
