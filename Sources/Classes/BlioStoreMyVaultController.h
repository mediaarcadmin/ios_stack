//
//  BlioStoreMyVaultController.h
//  BlioApp
//
//  Created by matt on 05/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioBookVaultManager.h"

static const NSInteger kBlioStoreMyVaultTag = 3;



@interface BlioStoreMyVaultController : UITableViewController<NSFetchedResultsControllerDelegate> {
	BlioBookVaultManager* _vaultManager;
	NSFetchedResultsController * fetchedResultsController;
    NSManagedObjectContext *_managedObjectContext;
    id <BlioProcessingDelegate> processingDelegate;

}
@property (nonatomic, assign) id <BlioProcessingDelegate> processingDelegate;
@property (nonatomic, retain) BlioBookVaultManager* vaultManager;
@property (nonatomic, retain) NSFetchedResultsController* fetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

- (id)initWithVaultManager:(BlioBookVaultManager*)vm;

@end
