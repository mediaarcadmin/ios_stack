//
//  EucChapterNameFormatting.h
//  Eucalyptus
//
//  Created by James Montgomerie on 09/03/2009.
//  Copyright 2009 James Montgomerie. All rights reserved.
//

#import <Foundation/Foundation.h>

@class THPair;

@interface NSString (EucChapterNameFormatting) 

- (THPair *)splitAndFormattedChapterName;
- (NSString *)mainChapterName;

@end
