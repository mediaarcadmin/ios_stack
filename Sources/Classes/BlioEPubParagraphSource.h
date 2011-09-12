//
//  BlioEPubParagraphSource.h
//  BlioApp
//
//  Created by James Montgomerie on 21/04/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BlioParagraphSource.h"

@class BlioEPubBook, EucEPubPageLayoutController;

@interface BlioEPubParagraphSource : NSObject <BlioParagraphSource> {
    NSManagedObjectID *_bookID;
    BlioEPubBook *_ePubBook;
}

- (id)initWithBookID:(NSManagedObjectID *)bookID;

@end
