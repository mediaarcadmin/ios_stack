//
//  BlioEPubParagraphSource.h
//  BlioApp
//
//  Created by James Montgomerie on 21/04/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioParagraphSource.h"

@class EucBUpeBook, EucBUpePageLayoutController;

@interface BlioEPubParagraphSource : NSObject <BlioParagraphSource> {
    EucBUpeBook *_bUpeBook;
    EucBUpePageLayoutController *_layoutController;
}

- (id)initWitBUpeBook:(EucBUpeBook *)bUpeBook;

@end
