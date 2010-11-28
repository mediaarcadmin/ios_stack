//
//  BlioEPubPaginateOperation.h
//  BlioApp
//
//  Created by James Montgomerie on 17/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioProcessing.h"

@class EucBookPaginator;

@interface BlioFlowPaginateOperation : BlioProcessingOperation {
    BOOL executing;
    BOOL finished;
    
    EucBookPaginator *paginator;
    NSString *bookTitle;
    CFAbsoluteTime startTime;
    
    BOOL bookCheckedOut;
}

@end
