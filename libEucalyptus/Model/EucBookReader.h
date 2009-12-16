//
//  EucBookReader.h
//  libEucalyptus
//
//  Created by James Montgomerie on 26/07/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EucGutenbergBook;
@protocol EucBookParagraph, EucBook;

@protocol EucBookReader <NSObject>

@required
@property (nonatomic, readonly) id<EucBook>book;

- (id)initWithBook:(id<EucBook>)book;
- (id<EucBookParagraph>)paragraphAtOffset:(size_t)offset maxOffset:(size_t)maxOffset;

@optional
@property (nonatomic, assign) BOOL shouldCollectPaginationData;
- (void)savePaginationDataToDirectoryAt:(NSString *)path;

@end
