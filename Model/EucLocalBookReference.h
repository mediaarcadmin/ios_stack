/*
 *  EucLocalBookReference.h
 *  Eucalyptus
 *
 *  Created by James Montgomerie on 28/07/2009.
 *  Copyright 2009 James Montgomerie. All rights reserved.
 *
 */

#import <UIKit/UIKit.h>

extern NSString* const kXAttrBookTextFileName;
extern NSString* const kXAttrIndexVersion;
extern NSString* const kXAttrParserVersion;

@protocol EucLocalBookReference <NSObject> 
    
@property (nonatomic, readonly) CGFloat percentThroughBook;
@property (nonatomic, readonly) CGFloat percentAnalysed;
@property (nonatomic, readonly) CGFloat percentPaginated;
@property (nonatomic, readonly) BOOL paginationIsComplete;
@property (nonatomic, readonly) BOOL parsingIsComplete;
@property (nonatomic, assign) NSInteger indexVersion;
@property (nonatomic, assign) NSInteger parserVersion;

@end
