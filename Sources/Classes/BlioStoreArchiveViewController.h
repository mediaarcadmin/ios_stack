//
//  BlioStoreArchiveViewController.h
//  BlioApp
//
//  Created by matt on 05/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "BlioProcessing.h"

static const NSInteger kBlioStoreMyVaultTag = 3;



@interface BlioStoreArchiveViewController : UITableViewController<NSFetchedResultsControllerDelegate> {
	NSFetchedResultsController * fetchedResultsController;
    NSManagedObjectContext *_managedObjectContext;
    id <BlioProcessingDelegate> processingDelegate;
	NSUInteger maxLayoutPageEquivalentCount;
	UILabel * noResultsLabel;

}
@property (nonatomic, assign) id <BlioProcessingDelegate> processingDelegate;
@property (nonatomic, retain) NSFetchedResultsController* fetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, assign) NSUInteger maxLayoutPageEquivalentCount;
@property (nonatomic, retain) UILabel * noResultsLabel;

-(void)calculateMaxLayoutPageEquivalentCount;
-(void)fetchResults;
@end
