//
//  BlioBookSearchController.h
//  BlioApp
//
//  Created by matt on 01/06/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioParagraphSource.h"

@interface BlioBookSearchController : NSObject {
    id<BlioParagraphSource> paragraphSource
}

@property (nonatomic, assign) id<BlioParagraphSource> paragraphSource;

- (id)initWithParagraphSource:(id<BlioParagraphSource>)aParagraphSource;
- (id)findString:(NSString *)string fromParagraphWithID:(id)startParagraphID;

@end
