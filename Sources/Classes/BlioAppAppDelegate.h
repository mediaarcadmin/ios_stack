//
//  BlioAppAppDelegate.h
//  BlioApp
//
//  Created by James Montgomerie on 16/12/2009.
//  Copyright Things Made Out Of Other Things 2009. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "BlioProcessingManager.h"
#import "BlioBook.h"
#import "Reachability.h"

static NSString * const BlioApplicationDidBecomeActiveNotification = @"BlioApplicationDidBecomeActiveNotification";

#undef BLIO_NSXMLPARSER_DELEGATE
#if TARGET_OS_IPHONE && (__IPHONE_OS_VERSION_MAX_ALLOWED >= 40000)
 #define BLIO_NSXMLPARSER_DELEGATE <NSXMLParserDelegate>
#else
 #define BLIO_NSXMLPARSER_DELEGATE 
#endif

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

