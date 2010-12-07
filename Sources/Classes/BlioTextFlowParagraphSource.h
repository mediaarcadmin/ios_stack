//
//  BlioTextFlowParagraphSource.h
//  BlioApp
//
//  Created by James Montgomerie on 14/04/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BlioParagraphSource.h"

@class BlioTextFlow, BlioTextFlowFlowTree, BlioFlowEucBook, BlioTextFlowParagraphSource;

@interface BlioTextFlowParagraphSource : NSObject <BlioParagraphSource> {
    BlioTextFlow *textFlow;
    
    NSUInteger currentFlowTreeIndex;
    BlioTextFlowFlowTree *currentFlowTree;
    
    BlioFlowEucBook *xamlEucBook;
}

- (id)initWithBookID:(NSManagedObjectID *)bookID;

@end
