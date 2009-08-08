//
//  BookPageIndexPoint.h
//  Eucalyptus
//
//  Created by James Montgomerie on 04/09/2008.
//  Copyright 2008 James Montgomerie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <stdint.h>

typedef enum BookPageIndexPointSource {
    BookPageIndexPointSourceCoverPage = 1,
    BookPageIndexPointSourceCopyrightPage = 2,
    BookPageIndexPointSourceBook = 0,
    BookPageIndexPointSourceLicenceAppendix = 3,
} BookPageIndexPointSource; 

@interface EucBookPageIndexPoint : NSObject {
    uint32_t _startOfParagraphByteOffset;
    uint32_t _startOfPageParagraphWordOffset;
    uint16_t _startOfPageWordHyphenOffset;
    uint16_t _source;
}

@property (nonatomic, assign) uint32_t startOfParagraphByteOffset;
@property (nonatomic, assign) uint32_t startOfPageParagraphWordOffset;
@property (nonatomic, assign) uint16_t startOfPageWordHyphenOffset;
@property (nonatomic, assign) uint16_t source;

+ (off_t)sizeOnDisk;

+ (EucBookPageIndexPoint *)bookPageIndexPointFromFile:(NSString *)path;
+ (EucBookPageIndexPoint *)lastBookPageIndexPointFromFile:(NSString *)path;

+ (EucBookPageIndexPoint *)bookPageIndexPointFromOpenFD:(int)fd;
- (BOOL)writeToOpenFD:(int)fd;

- (NSComparisonResult)compare:(EucBookPageIndexPoint *)rhs;

@end
