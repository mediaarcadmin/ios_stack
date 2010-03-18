//
//  BookPageIndexPoint.h
//  libEucalyptus
//
//  Created by James Montgomerie on 04/09/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <stdint.h>

@interface EucBookPageIndexPoint : NSObject {
    uint32_t _source;
    uint32_t _block;
    uint32_t _word;
    uint32_t _element;
}

@property (nonatomic, assign) uint32_t source;
@property (nonatomic, assign) uint32_t block;
@property (nonatomic, assign) uint32_t word;
@property (nonatomic, assign) uint32_t element;

+ (off_t)sizeOnDisk;

+ (EucBookPageIndexPoint *)bookPageIndexPointFromFile:(NSString *)path;
+ (EucBookPageIndexPoint *)lastBookPageIndexPointFromFile:(NSString *)path;

+ (EucBookPageIndexPoint *)bookPageIndexPointFromOpenFD:(int)fd;
- (BOOL)writeToOpenFD:(int)fd;

- (NSComparisonResult)compare:(EucBookPageIndexPoint *)rhs;

@end
