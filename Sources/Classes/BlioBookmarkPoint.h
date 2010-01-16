//
//  BlioBookmarkPoint.h
//  BlioApp
//
//  Created by James Montgomerie on 15/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BlioBookmarkPoint : NSObject {
    NSInteger layoutPage;
    uint32_t ePubParagraphId;
    uint32_t ePubWordOffset;
    uint32_t ePubHyphenOffset;
}

@property (nonatomic, assign) NSInteger layoutPage;
@property (nonatomic, assign) uint32_t ePubParagraphId;
@property (nonatomic, assign) uint32_t ePubWordOffset;
@property (nonatomic, assign) uint32_t ePubHyphenOffset;

@end
