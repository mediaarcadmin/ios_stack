//
//  BlioFlowEucBook.h
//  BlioApp
//
//  Created by James Montgomerie on 19/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <libEucalyptus/EucBUpeBook.h>

@class BlioBook, BlioTextFlow;

@interface BlioFlowEucBook : EucBUpeBook {
    NSManagedObjectID *bookID;
    BOOL fakeCover;
    BlioTextFlow *textFlow;
}

- (id)initWithBookID:(NSManagedObjectID *)blioBookID;

@end
