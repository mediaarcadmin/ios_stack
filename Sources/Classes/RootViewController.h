//
//  RootViewController.h
//  BlioApp
//
//  Created by James Montgomerie on 16/12/2009.
//  Copyright Things Made Out Of Other Things 2009. All rights reserved.
//

@interface RootViewController : UITableViewController {
    NSString *_currentBookPath;
    NSString *_currentPdfPath;
}

@property (nonatomic, retain) NSString *currentBookPath;
@property (nonatomic, retain) NSString *currentPdfPath;

@end
