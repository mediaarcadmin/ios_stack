/*
 *  EucBook.h
 *  Eucalyptus
 *
 *  Created by James Montgomerie on 29/07/2009.
 *  Copyright 2009 James Montgomerie. All rights reserved.
 *
 */

@protocol EucBookReader;

@class EucBookPageIndexPoint, EucBookSection;

@protocol EucBook <NSObject>

@property (nonatomic, readonly) id<EucBookReader> reader;
@property (nonatomic, copy) EucBookPageIndexPoint *currentPageIndexPoint;

- (NSString *)etextNumber;
- (NSString *)title;
- (NSString *)author;
- (NSString *)path;
- (size_t)startOffset;

- (Class)pageLayoutControllerClass;

@property (nonatomic, readonly) NSArray *sections;
- (EucBookSection *)sectionWithUuid:(NSString *)uuid;
- (EucBookSection *)topLevelSectionForByteOffset:(NSUInteger)byteOffset;
- (EucBookSection *)previousTopLevelSectionForByteOffset:(NSUInteger)byteOffset;
- (EucBookSection *)nextTopLevelSectionForByteOffset:(NSUInteger)byteOffset;

// Some UUIDs (like HTML anchors) don't correspond to sections. 
- (BOOL)hasByteOffsetForUuid:(NSString *)uuid;
- (NSUInteger)byteOffsetForUuid:(NSString *)uuid;
- (NSArray *)bookPageIndexesForFontFamily:(NSString *)fontFamily;

/*
@property (nonatomic, readonly) BookSection *firstSection;
@property (nonatomic, readonly) off_t bytesInReadableSections;

@property (nonatomic, readonly) BOOL canDisplayCurrentPageIndexPoint;
@property (nonatomic, readonly) EucGutenbergBook *licenceAppendix;

- (id)initWithTitle:(NSString *)title author:(NSString *)author etextNumber:(NSInteger)etextNumber path:(NSString *)path filename:(NSString *)filename encoding:(NSStringEncoding)encoding;
- (void)addSection:(BookSection *)section;
- (BookSection *)sectionForByteOffset:(NSUInteger)byteOffset;
- (BookSection *)previousTopLevelSectionForByteOffset:(NSUInteger)byteOffset;
- (BookSection *)nextTopLevelSectionForByteOffset:(NSUInteger)byteOffset;
- (BookSection *)contentsSection;
- (BookSection *)sectionWithUuid:(NSString *)uuid;

- (void)setLineAttribute:(BookTextStyle *)attribute forOffset:(off_t)offset;
- (BookTextStyle *)lineAttributeForOffset:(off_t)offset;

- (NSArray *)bookPageIndexesForFontFamily:(NSString *)familyName;

- (void)resetCurrentPageIndexPoint;

// To be used only for testing:
- (void)resetParsedMetadata;
*/

@end