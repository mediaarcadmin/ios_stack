//
//  BlioAppAppDelegate.m
//  BlioApp
//
//  Created by James Montgomerie on 16/12/2009.
//  Copyright Things Made Out Of Other Things 2009. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import <libEucalyptus/EucSharedHyphenator.h>
#import <pthread.h>
#import "BlioAppAppDelegate.h"
#import "BlioLibraryViewController.h"

static NSString * const kBlioInBookViewDefaultsKey = @"inBookView";

@interface BlioAppAppDelegate (private)
- (NSString *)dynamicDefaultPngPath;
@end

@implementation BlioAppAppDelegate

@synthesize window;
@synthesize navigationController;
@synthesize libraryController;

#pragma mark -
#pragma mark Application lifecycle

- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    // Override point for customization after app launch   
	//[window addSubview:[navigationController view]];

    
    NSString *dynamicDefaultPngPath = [self dynamicDefaultPngPath];
    NSData *imageData = [NSData dataWithContentsOfFile:dynamicDefaultPngPath];
    
    // After loading the image data, but before decoding it, remove it from 
    // the filesystem in case the PNG is corrupt.
    unlink([dynamicDefaultPngPath fileSystemRepresentation]);
    
    if(!imageData) {
        imageData = [NSData dataWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"LibraryGridViewController.png"]];
    }
    
    UIImage *dynamicDefaultImage = [UIImage imageWithData:imageData];
    if(!dynamicDefaultImage) {
        NSLog(@"Could not load dynamic default.png");
    } else {
        window.backgroundColor = [UIColor colorWithPatternImage:dynamicDefaultImage];
    }
    
    imageData = [NSData dataWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Default.png"]];
    realDefaultImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:imageData]];
    CGRect defaultFrame = realDefaultImageView.frame;
    defaultFrame.origin.y = CGRectGetHeight(window.bounds) - CGRectGetHeight(defaultFrame);
    [realDefaultImageView setFrame:defaultFrame];
    
    [window addSubview:realDefaultImageView];
    [window makeKeyAndVisible];
        
    [self performSelector:@selector(delayedApplicationDidFinishLaunching:) withObject:application afterDelay:0];
}

static void *background_init_thread(void * arg) {
    initialise_shared_hyphenator();
    return NULL;
}

- (void)performBackgroundInitialisation {    
    // Initialising the hyphenator is expensive, so we start it as early as possible
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    
    struct sched_param param = {0};
    int ret = pthread_attr_getschedparam(&attr, &param);
    if(ret != 0) {
        NSLog(@"pthread_attr_getschedparam returned %ld", (long)ret);
    }
    param.sched_priority = sched_get_priority_min(SCHED_RR);
    ret = pthread_attr_setschedparam(&attr, &param);
    if(ret != 0) {
        NSLog(@"pthread_attr_setschedparam returned %ld", (long)ret);
    }
    
    pthread_t hit;
    ret = pthread_create(&hit, &attr, background_init_thread, NULL);
    if(ret != 0) {
        NSLog(@"pthread_create returned %ld", (long)ret);
    }
    
    ret = pthread_attr_destroy(&attr);
    if(ret != 0) {
        NSLog(@"pthread_attr_destroy returned %ld", (long)ret);
    }    
}

- (void)switchStatusBar
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

- (void)delayedApplicationDidFinishLaunching:(UIApplication *)application {
    [self performBackgroundInitialisation];
    
    NSManagedObjectContext *moc = [self managedObjectContext];
	
	// resume previous processing operations
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"BlioMockBook" inManagedObjectContext:moc]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"processingComplete == %@", [NSNumber numberWithInt:kBlioMockBookProcessingStateIncomplete]]];
	
	NSError *errorExecute = nil;
    NSArray *results = [moc executeFetchRequest:fetchRequest error:&errorExecute]; 
    
	
    if (errorExecute) {
        NSLog(@"Error getting incomplete book results. %@, %@", errorExecute, [errorExecute userInfo]); 
    }
    else {
		if ([results count] > 0) {
			NSLog(@"Found non-paused incomplete book results, will resume..."); 
			for (BlioMockBook * book in results) {
//				NSLog(@"mo sourceSpecificID:%@ sourceID:%@",[mo valueForKey:@"sourceSpecificID"],[mo valueForKey:@"sourceID"]);
				[[self processingManager] enqueueBook:book];
			}
		}
		else {
//			NSLog(@"No incomplete book results to resume."); 
		}
	}
    [fetchRequest release];
	
	// end resume previous processing operations
	
    [libraryController setManagedObjectContext:moc];
    [libraryController setProcessingDelegate:[self processingManager]];
    
    [window addSubview:[navigationController view]];
    [window sendSubviewToBack:[navigationController view]];
    window.backgroundColor = [UIColor blackColor];
    
    [UIView beginAnimations:@"FadeOutRealDefault" context:nil];
    [UIView setAnimationDuration:1.0/5.0];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView setAnimationDelegate:realDefaultImageView];
    [UIView setAnimationDidStopSelector:@selector(removeFromSuperview)];
    realDefaultImageView.alpha = 0;
    realDefaultImageView.transform = CGAffineTransformMakeScale(1.2f, 1.2f);
    [UIView commitAnimations];    
    
    [realDefaultImageView release];
    realDefaultImageView = nil;
    
    [self performSelector:@selector(switchStatusBar) withObject:nil afterDelay:0];
}


- (NSString *)dynamicDefaultPngPath {
    NSString *tmpDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [tmpDir stringByAppendingPathComponent:@".BlioDynamicDefault.png"];
}


- (void)applicationWillTerminate:(UIApplication *)application {
	// Save data if appropriate
    NSError *error;
    if (![[self managedObjectContext] save:&error])
        NSLog(@"Save failed with error: %@, %@", error, [error userInfo]);
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
    [managedObjectContext release];
    [managedObjectModel release];
    [persistentStoreCoordinator release];
    [processingManager release];
	[navigationController release];
    [libraryController release];
	[window release];
	[super dealloc];
}

#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
	
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return managedObjectContext;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSURL *storeUrl = [NSURL fileURLWithPath: [basePath stringByAppendingPathComponent: @"Blio.sqlite"]];
	
	NSError *error;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error]) {
        // Handle error
        // Delete the current store and start again
        // TODO - this is just a demo convenience - you would not want to do this in real deployment
        NSError *fileError;
        if (![[NSFileManager defaultManager] removeItemAtPath:[[storeUrl absoluteURL] path] error:&fileError])
             NSLog(@"Could not delete the existing persistent store: %@, %@", fileError, [fileError userInfo]);
            
        // Attempt to create the store again
        if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error])
            NSLog(@"Could not create persistent store: %@, %@", error, [error userInfo]);
        else
            NSLog(@"Persistent store recreated after deleting the existing one");
        
   }    
	
    return persistentStoreCoordinator;
}

/**
 Returns the processing manager for the application.
 If it doesn't already exist, it is created
 */
- (BlioProcessingManager *)processingManager {
	
    if (processingManager != nil) {
        return processingManager;
    }
	
    processingManager = [[BlioProcessingManager alloc] initWithManagedObjectContext:[self managedObjectContext]];
   	
    return processingManager;
}

@end

