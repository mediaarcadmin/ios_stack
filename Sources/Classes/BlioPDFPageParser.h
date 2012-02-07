//
//  BlioPDFPageParser.h
//  BlioApp
//
//  Created by Matt Farrugia on 05/02/2012.
//  Copyright (c) 2012 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kBlioPDFPositionAttribute;

@protocol BlioPDFResourceDataSource;

@interface BlioPDFPageParser : NSObject

- (id)initWithPageRef:(CGPDFPageRef)aPageRef resourceDataSource:(id<BlioPDFResourceDataSource>)dataSource;
- (void)parse;
- (NSAttributedString *)attributedString;

@end
