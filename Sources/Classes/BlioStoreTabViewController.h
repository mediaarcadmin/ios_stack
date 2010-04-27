//
//  BlioStoreTabViewController.h
//  BlioApp
//
//  Created by matt on 05/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioProcessing.h"
#import <CoreData/CoreData.h>
#import "BlioBookVaultManager.h"

@interface BlioStoreTabViewController : UITabBarController <UITabBarControllerDelegate> {
    id <BlioProcessingDelegate> processingDelegate;
	NSManagedObjectContext *managedObjectContext;
}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

- (id)initWithProcessingDelegate:(id<BlioProcessingDelegate>)aProcessingDelegate managedObjectContext:(NSManagedObjectContext*)moc vaultManager:(BlioBookVaultManager*)aVaultManager;

@end
