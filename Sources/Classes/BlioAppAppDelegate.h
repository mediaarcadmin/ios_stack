//
//  BlioAppAppDelegate.h
//  BlioApp
//
//  Created by James Montgomerie on 16/12/2009.
//  Copyright Things Made Out Of Other Things 2009. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "BlioProcessingManager.h"
#import "BlioMockBook.h"
#import "Reachability.h"

@class BlioLibraryViewController;

@interface BlioAppAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    UINavigationController *navigationController;
    BlioLibraryViewController *libraryController;
    
    UIImageView *realDefaultImageView;
    
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;	    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    
    BlioProcessingManager *processingManager;
	NetworkStatus networkStatus;
	Reachability * internetReach;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet BlioLibraryViewController *libraryController;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) BlioProcessingManager *processingManager;
@property (nonatomic, assign, readwrite) NetworkStatus networkStatus;
@property (nonatomic, retain, readwrite) Reachability * internetReach;

@end

