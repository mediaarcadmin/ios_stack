//
//  BlioAppAppDelegate.m
//  BlioApp
//
//  Created by James Montgomerie on 16/12/2009.
//  Copyright Things Made Out Of Other Things 2009. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <libEucalyptus/EucSharedHyphenator.h>
#import <pthread.h>
#import "BlioAppAppDelegate.h"
#import "BlioLibraryViewController.h"
#import "BlioAlertManager.h"
#import "BlioLoginViewController.h"
#import "BlioStoreManager.h"
#import "AcapelaSpeech.h"
#import "BlioAppSettingsConstants.h"
// RESTORE FOR OLD DRM INTERFACE
//#import "BlioDrmManager.h"
#import "BlioBookManager.h"
#import <unistd.h>

static NSString * const kBlioInBookViewDefaultsKey = @"inBookView";

@interface BlioAppAppDelegate (private)
- (NSString *)dynamicDefaultPngPath;
@end

@implementation BlioAppAppDelegate

@synthesize window;
@synthesize navigationController;
@synthesize libraryController;
@synthesize networkStatus;
@synthesize internetReach;

#pragma mark -
#pragma mark Application lifecycle

- (void)applicationDidFinishLaunching:(UIApplication *)application {  
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	NSError * audioError = nil;
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&audioError];
	if (audioError) {
		NSLog(@"[ERROR: could not set AVAudioSessionCategory with error: %@, %@", audioError, [audioError userInfo]);
	}
	
	NSArray * applicationSupportPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportPath = ([applicationSupportPaths count] > 0) ? [applicationSupportPaths objectAtIndex:0] : nil;

	BOOL isDir;
	if (![[NSFileManager defaultManager] fileExistsAtPath:applicationSupportPath isDirectory:&isDir] || !isDir) {
		NSError * createApplicationSupportDirError = nil;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:applicationSupportPath withIntermediateDirectories:YES attributes:nil error:&createApplicationSupportDirError]) {
			NSLog(@"ERROR: could not create Application Support directory in the Library directory! %@, %@",createApplicationSupportDirError, [createApplicationSupportDirError userInfo]);
		}
		else NSLog(@"Created Application Support directory within Library...");
	}
	
    // Override point for customization after app launch   
	//[window addSubview:[navigationController view]];

    // TODO - update this with a proper check for TTS being enabled
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kBlioTTSEnabledDefaultsKey];
    
    NSString *dynamicDefaultPngPath = [self dynamicDefaultPngPath];
    NSData *imageData = [NSData dataWithContentsOfFile:dynamicDefaultPngPath];
    
    // After loading the image data, but before decoding it, remove it from 
    // the filesystem in case the PNG is corrupt.
    unlink([dynamicDefaultPngPath fileSystemRepresentation]);
    
//    if(!imageData) {
//		NSLog(@"No Dynamic PNG data available, showing image of library view...");
//        imageData = [NSData dataWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"LibraryGridViewController.png"]];
//    }
//    
//    UIImage *dynamicDefaultImage = [UIImage imageWithData:imageData];
//    if(!dynamicDefaultImage) {
//        NSLog(@"Could not load dynamic default.png");
//    } else {
//        window.backgroundColor = [UIColor colorWithPatternImage:dynamicDefaultImage];
//    }

	[window addSubview:[navigationController view]];
    [window sendSubviewToBack:[navigationController view]];
    window.backgroundColor = [UIColor blackColor];
	
	// Rotates the view.
	CGAffineTransform transform = CGAffineTransformIdentity;
    
    UIScreen *screen = [UIScreen mainScreen];
    NSString *uiScaleAdditionString = @"";
    if([screen respondsToSelector:@selector(scale)]) {
        CGFloat scale = [screen scale];
        if(scale != 1.0f) {
            uiScaleAdditionString = [NSString stringWithFormat:@"@%ldx", (long)scale]; 
        }
    }
    
tryAgain:
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
//		if ( ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft) || ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight) )
//		{
//			NSLog(@"Using landscape image");
//			imageData = [NSData dataWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"Default-Landscape%@.png", uiScaleAdditionString]]];
//			transform = CGAffineTransformMakeRotation(3.14159/2);
//		}
//		else
//		{
//			NSLog(@"Using portrait image");
//			imageData = [NSData dataWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"Default-Portrait%@.png", uiScaleAdditionString]]];
//		}
		imageData = [NSData dataWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"Default-Portrait%@.png", uiScaleAdditionString]]];
	} else {
		imageData = [NSData dataWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"Default%@.png", uiScaleAdditionString]]];
	}
        
    if(!imageData && ![uiScaleAdditionString isEqualToString:@""]) {
        // If we didn't find a good image to use, try again with no scale factor.
        // Sorry about the goto, seemed clearer than other ways...
        uiScaleAdditionString = @"";
        goto tryAgain;
    }

    realDefaultImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:imageData]];
    realDefaultImageView.frame = window.bounds;
    realDefaultImageView.contentMode = UIViewContentModeScaleToFill;
    realDefaultImageView.transform = transform;
    [window addSubview:realDefaultImageView];
    [window makeKeyAndVisible];

	self.internetReach = [Reachability reachabilityForInternetConnection];
	self.networkStatus = [self.internetReach currentReachabilityStatus];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
	[self.internetReach startNotifer];
	
    NSPersistentStoreCoordinator *psc = [self persistentStoreCoordinator];
	NSManagedObjectContext *moc = [self managedObjectContext];

    BlioBookManager *bookManager = [BlioBookManager sharedBookManager];
    bookManager.persistentStoreCoordinator = psc;
    bookManager.managedObjectContextForCurrentThread = moc; // Use our managed object contest for calls that are made on the main thread.
    
    libraryController.managedObjectContext = moc;
    libraryController.processingDelegate = self.processingManager;

	//[[BlioDrmManager getDrmManager] initialize];
	
	// This did happen in BlioDrmManager, but shouldn't happen in BlioDrmSessionManager.
	// Copy DRM resources to writeable directory.
	NSError* err;	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString* rsrcWmModelKey = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/DRM/priv.dat"]; 
	NSString* docsWmModelKey = [documentsDirectory stringByAppendingString:@"/priv.dat"];
	[[NSFileManager defaultManager] copyItemAtPath:rsrcWmModelKey toPath:docsWmModelKey error:&err];
	NSString* rsrcWmModelCert = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/DRM/devcerttemplate.dat"]; 
	NSString* docsWmModelCert = [documentsDirectory stringByAppendingString:@"/devcerttemplate.dat"];
	[[NSFileManager defaultManager] copyItemAtPath:rsrcWmModelCert toPath:docsWmModelCert error:&err];
	NSString* rsrcPRModelCert = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/DRM/iphonecert.dat"]; 
	NSString* docsPRModelCert = [documentsDirectory stringByAppendingString:@"/iphonecert.dat"];
	[[NSFileManager defaultManager] copyItemAtPath:rsrcPRModelCert toPath:docsPRModelCert error:&err];
	NSString* rsrcPRModelKey = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/DRM/iphonezgpriv.dat"]; 
	NSString* docsPRModelKey = [documentsDirectory stringByAppendingString:@"/iphonezgpriv.dat"];
	[[NSFileManager defaultManager] copyItemAtPath:rsrcPRModelKey toPath:docsPRModelKey error:&err];

    [self performSelector:@selector(delayedApplicationDidFinishLaunching:) withObject:application afterDelay:0];
    
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

-(void)loginDismissed:(NSNotification*)note {
	if ([[[note userInfo] valueForKey:@"sourceID"] intValue] == BlioBookSourceOnlineStore) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioLoginFinished object:[BlioStoreManager sharedInstance]];
		if ([[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore]) {
			[self.processingManager resumeProcessingForSourceID:BlioBookSourceOnlineStore];
			[[BlioStoreManager sharedInstance] retrieveBooksForSourceID:BlioBookSourceOnlineStore];
		}
		else {
			//			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"For Your Information...",@"\"For Your Information...\" Alert message title")
			//										 message:[NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"LOGIN_REQUIRED_FOR_UPDATING_PAID_BOOKS_VAULT",nil,[NSBundle mainBundle],@"Login is required to update your Vault. In the meantime, only previously synced books will display.",@"Alert message informing the end-user that login is required to update the Vault. In the meantime, previously synced books will display.")]
			//										delegate:self
			//							   cancelButtonTitle:@"OK"
			//							   otherButtonTitles:nil];			
		}
	}
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
    
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *docsPath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString *voicesPath = [docsPath stringByAppendingPathComponent:@"TTS"];

	BOOL isDir;
	if (![[NSFileManager defaultManager] fileExistsAtPath:voicesPath isDirectory:&isDir] || !isDir) {
		NSError * createTTSDirError = nil;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:voicesPath withIntermediateDirectories:YES attributes:nil error:&createTTSDirError]) {
			NSLog(@"ERROR: could not create TTS directory in the Documents directory! %@, %@",createTTSDirError, [createTTSDirError userInfo]);
		}
		else NSLog(@"Created TTS directory within Documents...");
	}
	
#ifdef DEMO_MODE
	
    NSString *manualVoiceDestinationPath = [voicesPath stringByAppendingPathComponent:@"Acapela For iPhone LF USEnglish Heather"];
	NSString *manualVoiceCopyPath = 
	[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Acapela For iPhone LF USEnglish Heather"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:manualVoiceCopyPath] && ![[NSFileManager defaultManager] fileExistsAtPath:manualVoiceDestinationPath]) {
		NSError * manualVoiceCopyError = nil;
		if (![[NSFileManager defaultManager] copyItemAtPath:manualVoiceCopyPath toPath:manualVoiceDestinationPath error:&manualVoiceCopyError]) 
			NSLog(@"ERROR: could not manually copy the Heather voice directory to the Documents/TTS directory! %@, %@",manualVoiceCopyError, [manualVoiceCopyError userInfo]);
		else NSLog(@"Copied Heather into TTS directory...");
	}
		
#endif
	
	NSLog(@"voicesPath: %@",voicesPath);
	[AcapelaSpeech setVoicesDirectoryArray:[NSArray arrayWithObject:voicesPath]];
	    
	[BlioStoreManager sharedInstance].rootViewController = navigationController;
	[BlioStoreManager sharedInstance].processingDelegate = self.processingManager;

	if (self.networkStatus != NotReachable) {
		if ([[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore]) {
			[[BlioStoreManager sharedInstance] retrieveBooksForSourceID:BlioBookSourceOnlineStore];
		}
		else {
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDismissed:) name:BlioLoginFinished object:[BlioStoreManager sharedInstance]];
			[[BlioStoreManager sharedInstance] requestLoginForSourceID:BlioBookSourceOnlineStore];
		}		
		[self.processingManager resumeProcessing];
	}	
	
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
    NSString *tmpDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [tmpDir stringByAppendingPathComponent:@".BlioDynamicDefault.png"];
}


- (void)applicationWillTerminate:(UIApplication *)application {
	// Save data if appropriate
    NSError *error;
    if (![[self managedObjectContext] save:&error])
        NSLog(@"[BlioAppAppDelegate applicationWilTerminate] Save failed with error: %@, %@", error, [error userInfo]);
}

#pragma mark -
#pragma mark UIApplicationDelegate - Background Tasks

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200

-(void)applicationDidEnterBackground:(UIApplication *)application {
    NSError *error;
    if (![[self managedObjectContext] save:&error])
        NSLog(@"[BlioAppAppDelegate applicationDidEnterBackground] Save failed with error: %@, %@", error, [error userInfo]);	
}

#endif

#pragma mark -
#pragma mark Network Reachability

//Called by Reachability whenever status changes.
- (void) reachabilityChanged: (NSNotification* )note
{
	NSLog(@"BlioAppAppDelegate reachabilityChanged");
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
	NetworkStatus previousNetStatus = self.networkStatus;
	self.networkStatus = [curReach currentReachabilityStatus];
	NSLog(@"previousNetStatus: %i",previousNetStatus);
	NSLog(@"self.networkStatus: %i",self.networkStatus);
	if (previousNetStatus != NotReachable && self.networkStatus == NotReachable) { // if changed from available to unavailable
		[self.processingManager stopDownloadingOperations];
		if ([[self.processingManager downloadOperations] count] > 0)
		{
			// ALERT user to what just happened.
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"For Your Information...",@"\"For Your Information...\" Alert message title")
															message:NSLocalizedStringWithDefaultValue(@"INTERNET_ACCESS_LOST",nil,[NSBundle mainBundle],@"Internet access has been lost, and any current downloads have been interrupted. Downloads will resume automatically once internet access is restored.",@"Alert message informing the end-user that downloads in progress have been suspended due to lost internet access.")
														   delegate:self
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
//			UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"For Your Information...",@"\"For Your Information...\" Alert message title")
//															message:[NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"INTERNET_ACCESS_LOST",nil,[NSBundle mainBundle],@"Internet access has been lost, and any current downloads have been interrupted. Downloads will resume automatically once internet access is restored.",@"Alert message informing the end-user that downloads in progress have been suspended due to lost internet access.")]
//														   delegate:self
//												  cancelButtonTitle:@"OK"
//												  otherButtonTitles:nil];
//			[alert show];
//			[alert release];
		}
	}
	else if (previousNetStatus == NotReachable && self.networkStatus != NotReachable) { // if changed from unavailable to available
		[self.processingManager resumeProcessing];
	}
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:managedObjectContext];
    [managedObjectContext release];
    [managedObjectModel release];
    [persistentStoreCoordinator release];
    [processingManager release];
	[navigationController release];
    [libraryController release];
	[window release];
	self.internetReach = nil;
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
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mergeChangesFromContextDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:nil];

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
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
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

- (void)mergeChangesFromContextDidSaveNotification:(NSNotification *)notification {
//	NSLog(@"BlioAppAppDelegate mergeChangesFromContextDidSaveNotification received...");	
	[[self managedObjectContext] mergeChangesFromContextDidSaveNotification:notification];
}

/**
 Returns the processing manager for the application.
 If it doesn't already exist, it is created
 */
- (BlioProcessingManager *)processingManager {
	
    if (processingManager != nil) {
        return processingManager;
    }
	
    processingManager = [[BlioProcessingManager alloc] init];
   	
    return processingManager;
}

@end

