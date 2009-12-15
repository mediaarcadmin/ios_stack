//
//  PaginateRootViewController.h
//  HHGG
//
//  Created by James Montgomerie on 05/08/2009.
//  Copyright James Montgomerie 2009. All rights reserved.
//


#import <UIKit/UIKit.h>

@class EucBookPaginator;

@interface PaginateRootViewController : UITableViewController {
    BOOL paginationUnderway;
    NSMutableArray *toPaginate;
    EucBookPaginator *paginator;
    
    BOOL saveImages;
}

@property (nonatomic, assign) BOOL paginationUnderway;

@end
