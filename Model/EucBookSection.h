//
//  BookSection.h
//  libEucalyptus
//
//  Created by James Montgomerie on 22/05/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kBookSectionPrefix;
extern NSString * const kBookSectionContents;
extern NSString * const kBookSectionIllustrationTable;
extern NSString * const kBookSectionChapter;
extern NSString * const kBookSectionNondescript;
extern NSString * const kBookSectionStandardPostfix;
extern NSString * const kBookSectionLicence;
extern NSString * const kBookSectionIllustrationReference;

extern NSString * const kBookSectionPropertyTitle;
extern NSString * const kBookSectionPropertyContentsList;

@interface EucBookSection : NSObject <NSCoding> {
    NSString *_uuid;
    NSString *_kind;
    off_t _startOffset;
    off_t _endOffset;
    NSMutableDictionary *_properties;
    NSMutableArray *_subsections;
}

@property (nonatomic, retain) NSString *kind;
@property (nonatomic, retain) NSString *uuid;
@property (nonatomic, assign) off_t startOffset;
@property (nonatomic, assign) off_t endOffset;
@property (nonatomic, readonly) NSDictionary *properties;
@property (nonatomic, readonly) NSArray *subsections;

- (void)setProperty:(NSString *)property forKey:(NSString *)key;
- (void)addSubsection:(EucBookSection *)subsection;

@end
