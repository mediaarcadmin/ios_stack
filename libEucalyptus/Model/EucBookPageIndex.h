//
//  BookPageIndex.h
//  libEucalyptus
//
//  Created by James Montgomerie on 04/07/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EucBookPageIndexPoint;
@protocol EucBook;

@interface EucBookPageIndex : NSObject {
    id<EucBook> _book;
    NSString *_fontFamily;
    NSUInteger _pointSize;
    
    int _fd;
    BOOL _isFinal;
    
    NSUInteger _lastPageNumber;
    off_t _lastOffset;
}

+ (NSUInteger)indexVersion;
+ (NSString *)filenameForPageIndexForFontFamily:(NSString *)fontFamilyName pointSize:(NSUInteger)fontSize;
+ (NSString *)constructionFilenameForPageIndexForFontFamily:(NSString *)fontFamilyName pointSize:(NSUInteger)fontSize;
+ (void)markBookBundleAsIndexConstructed:(NSString *)bundlePath;

+ (id)bookPageIndexForIndexInBook:(id<EucBook>)path forFontFamily:(NSString *)fontFamily pointSize:(NSUInteger)pointSize;
+ (NSArray *)bookPageIndexesForBook:(id<EucBook>)book forFontFamily:(NSString *)fontFamily;

@property (nonatomic, readonly) id<EucBook> book;
@property (nonatomic, readonly) NSString *fontFamily;
@property (nonatomic, readonly) NSUInteger pointSize;

@property (nonatomic, readonly) NSUInteger lastPageNumber;
@property (nonatomic, readonly) BOOL isFinal;
@property (nonatomic, readonly) off_t lastOffset;

- (EucBookPageIndexPoint *)indexPointForPage:(NSUInteger)pageNumber;
- (NSUInteger)pageForIndexPoint:(EucBookPageIndexPoint *)indexPoint;
- (NSUInteger)pageForByteOffset:(NSUInteger)byteOffset;
- (void)closeIndex;

- (NSComparisonResult)compare:(EucBookPageIndex *)rhs;

@end
