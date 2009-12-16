//
//  EucChapterNameFormatting.h
//  libEucalyptus
//
//  Created by James Montgomerie on 09/03/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class THPair;

@interface NSString (EucChapterNameFormatting) 

- (THPair *)splitAndFormattedChapterName;
- (NSString *)mainChapterName;

@end
