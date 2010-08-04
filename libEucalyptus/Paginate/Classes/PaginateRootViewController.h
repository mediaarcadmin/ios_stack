//
//  PaginateRootViewController.h
//  Paginate
//
//  Created by James Montgomerie on 05/08/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//


#import <UIKit/UIKit.h>

@class EucBookPaginator;

@interface PaginateRootViewController : UITableViewController {
    BOOL paginationUnderway;
    NSMutableArray *toPaginate;
    EucBookPaginator *paginator;
    
    BOOL saveImages;
    
    CFAbsoluteTime time;
}

@property (nonatomic, assign) BOOL paginationUnderway;

@end
