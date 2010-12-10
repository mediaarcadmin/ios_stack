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
#import "BlioStoreHelper.h"
#import "AcapelaSpeech.h"
#import "BlioAppSettingsConstants.h"
#import "BlioBookManager.h"
#import "BlioImportManager.h"
#import "BlioBook.h"
#import "BlioBookViewController.h"
#import "BlioDefaultViewController.h"
#import <libEucalyptus/THEventCapturingWindow.h>
#import <libEucalyptus/THUIDeviceAdditions.h>

@interface BlioAppAppDelegate ()

- (void)saveBookSnapshotIfAppropriate;

@property (nonatomic, assign) BOOL delayedDidFinishLaunchingLaunchComplete;
@property (nonatomic, retain) NSMutableArray *delayedURLOpens;

@end

@implementation BlioAppAppDelegate

@synthesize window;
@synthesize navigationController;
@synthesize libraryController;
@synthesize networkStatus;
@synthesize internetReach;

@synthesize delayedDidFinishLaunchingLaunchComplete;
@synthesize delayedURLOpens;


#pragma mark -
#pragma mark Application lifecycle

- (void)ensureCorrectCertsAvailable {
    // Copy DRM resources to writeable directory.
	NSError* err;	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	
	NSString* wmModelCertFilename = @"devcerttemplate.dat";
	NSString* prModelCertFilename = @"iphonecert.dat";
	
	NSString* sourceDir = [[NSBundle mainBundle] resourcePath];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		sourceDir = [sourceDir stringByAppendingPathComponent:@"DRM-iPad"];
    } else {
        sourceDir = [sourceDir stringByAppendingPathComponent:@"DRM"];
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString* rsrcWmModelCert = [sourceDir stringByAppendingPathComponent:wmModelCertFilename]; 
    NSString* docsWmModelCert = [documentsDirectory stringByAppendingPathComponent:wmModelCertFilename];
	[fileManager copyItemAtPath:rsrcWmModelCert toPath:docsWmModelCert error:&err];
    
	NSString* rsrcPRModelCert = [sourceDir stringByAppendingPathComponent:prModelCertFilename]; 
	NSString* docsPRModelCert = [documentsDirectory stringByAppendingPathComponent:prModelCertFilename];
	[fileManager copyItemAtPath:rsrcPRModelCert toPath:docsPRModelCert error:&err];    
}

- (void)ensureApplicationSupportAvailable {    
	NSArray *applicationSupportPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportPath = ([applicationSupportPaths count] > 0) ? [applicationSupportPaths objectAtIndex:0] : nil;
    
    BOOL isDir;
	if (![[NSFileManager defaultManager] fileExistsAtPath:applicationSupportPath isDirectory:&isDir] || !isDir) {
		NSError * createApplicationSupportDirError = nil;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:applicationSupportPath withIntermediateDirectories:YES attributes:nil error:&createApplicationSupportDirError]) {
			NSLog(@"ERROR: could not create Application Support directory in the Library directory! %@, %@",createApplicationSupportDirError, [createApplicationSupportDirError userInfo]);
		}
		else NSLog(@"Created Application Support directory within Library...");
	}    
}

- (void)ensureTTSAvailable {
 	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *docsPath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString *voicesPath = [docsPath stringByAppendingPathComponent:@"TTS"];
    
	BOOL isDir;
	if (![[NSFileManager defaultManager] fileExistsAtPath:voicesPath isDirectory:&isDir] || !isDir) {
		NSError * createTTSDirError = nil;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:voicesPath withIntermediateDirectories:YES attributes:nil error:&createTTSDirError]) {
			NSLog(@"ERROR: could not create TTS directory in the Application Support directory! %@, %@",createTTSDirError, [createTTSDirError userInfo]);
		}
		else NSLog(@"Created TTS directory within Application Support...");
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
}

- (BOOL)canOpenURL:(NSURL *)url {
    if ([url isFileURL]) {
		NSString * file = [url path]; 
		if ([file.pathExtension compare:@"epub" options:NSCaseInsensitiveSearch] == NSOrderedSame ||
            [file.pathExtension compare:@"pdf" options:NSCaseInsensitiveSearch] == NSOrderedSame || 
            [file.pathExtension compare:@"xps" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            return YES;
        } 
    }
    return NO;            
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

- (void)setUpDefaultImage
{
    realDefaultImageViewController = [[BlioDefaultViewController alloc] initWithNibName:nil bundle:nil];
    [self.window addSubview:realDefaultImageViewController.view];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // The idea here is to do as little as possible and load the faded book page very quickly.
    // We'll properly do everything else (including ap setup, loading the NIB etc). in 
    // -delayedApplicationDidFinishLaunching.
    
    self.window = [[[THEventCapturingWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    [self setUpDefaultImage];
    [window makeKeyAndVisible];    
    
    
    [self performSelector:@selector(delayedApplicationDidFinishLaunchingStep1:) withObject:application afterDelay:0];
    
    NSURL *launchURL = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
    if(launchURL) {
        BOOL canOpen = [self canOpenURL:launchURL];
        if(canOpen) {
            if([[UIDevice currentDevice] compareSystemVersion:@"4"] == NSOrderedAscending) {
                // There's a bug in < 4.0 that prevents handleOpenURL being  
                // called automatically.
                [self application:application handleOpenURL:launchURL];
            }
            return YES;
        }
        return NO;
    }    
    return YES;
}

-(BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
	//NSLog(@"opened app with URL: %@",[url absoluteString]);
	//[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"For Your Information...",@"\"For Your Information...\" Alert message title")
	//							 message:[NSString stringWithFormat:@"handleOpenURL: %@",[url absoluteString]]
    //                          delegate:nil
	//				   cancelButtonTitle:@"OK"
	//				   otherButtonTitles:nil];
    
    if([self canOpenURL:url]) {
        if(self.delayedDidFinishLaunchingLaunchComplete) {
            [[BlioImportManager sharedImportManager] importBookFromFilePath:[url path]];
        } else {
            NSMutableArray *myDelayedURLOpens = self.delayedURLOpens;
            if(!myDelayedURLOpens) {
                myDelayedURLOpens = [NSMutableArray array];
                self.delayedURLOpens = myDelayedURLOpens;
            }
            [myDelayedURLOpens addObject:url];
        }
        return YES;
	}
	return NO;
}


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
//	[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"For Your Information...",@"\"For Your Information...\" Alert message title")
//								 message:[NSString stringWithFormat:@"openURL: %@",[url absoluteString]]
//								delegate:nil
//					   cancelButtonTitle:@"OK"
//					   otherButtonTitles:nil];
	return [self application:application handleOpenURL:url];
}


- (void)delayedApplicationDidFinishLaunchingStep1:(UIApplication *)application {
    // Now that the view is loaded, and in the correct orientation, show the
    // book page if one was available.
    [realDefaultImageViewController fadeOutDefaultImageIfDynamicImageAlsoAvailable];
    
    // Defer again to allow the animation to start.
    [self performSelector:@selector(delayedApplicationDidFinishLaunchingStep2:) withObject:application afterDelay:0];
}

- (void)delayedApplicationDidFinishLaunchingStep2:(UIApplication *)application {
    [self performBackgroundInitialisation];
    
    [[NSBundle mainBundle] loadNibNamed:@"MainNavControllerAndLibraryView" owner:self options:nil];
    
    NSError * audioError = nil;
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&audioError];
	if (audioError) {
		NSLog(@"[ERROR: could not set AVAudioSessionCategory with error: %@, %@", audioError, [audioError userInfo]);
	}
    
    [self ensureApplicationSupportAvailable];
    
    [self ensureCorrectCertsAvailable];
    
    // TODO - update this with a proper check for TTS being enabled
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kBlioTTSEnabledDefaultsKey];
    
    [self ensureTTSAvailable];
    
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
    
	[BlioStoreManager sharedInstance].processingDelegate = self.processingManager;
	   
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDismissed:) name:BlioLoginFinished object:[BlioStoreManager sharedInstance]];

	[BlioStoreManager sharedInstance].rootViewController = navigationController;

	if (self.networkStatus != NotReachable) {
		if (![[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore]) {
			NSDictionary * loginCredentials = [[BlioStoreManager sharedInstance] savedLoginCredentials];
			if (loginCredentials && [loginCredentials objectForKey:@"username"] && [loginCredentials objectForKey:@"password"]) {
				[[BlioStoreManager sharedInstance] requestLoginForSourceID:BlioBookSourceOnlineStore];
			}
		}
		[self.processingManager resumeProcessing];
	}	
	
    
    BOOL openedBook;
    
    NSArray *openBookIDs = [[NSUserDefaults standardUserDefaults] objectForKey:kBlioOpenBookKey];
    if(openBookIDs.count == 2) {
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[NSEntityDescription entityForName:@"BlioBook" inManagedObjectContext:moc]];
		[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"sourceID == %@ && sourceSpecificID == %@",
                                    [openBookIDs objectAtIndex:0],
                                    [openBookIDs objectAtIndex:1]]];
        NSError *errorExecute = nil; 
		NSArray *results = [moc executeFetchRequest:fetchRequest error:&errorExecute]; 
        if(!errorExecute && results.count == 1) {
            [libraryController openBook:[results objectAtIndex:0]];
            openedBook = YES;
        }
    }
    
    // Must do the view adding in this order to get landscape support to work
    // correctly.
    [realDefaultImageViewController.view removeFromSuperview];
    [window addSubview:navigationController.view];
    [window addSubview:realDefaultImageViewController.view];
    [window sendSubviewToBack:navigationController.view];
    
    [realDefaultImageViewController fadeOutCompletly];
    [realDefaultImageViewController release];
    
    if(!openedBook) {
        [self performSelector:@selector(switchStatusBar) withObject:nil afterDelay:0];
    }
    
    for(NSURL *url in self.delayedURLOpens) {
        [self application:[UIApplication sharedApplication] handleOpenURL:url];
    }
    self.delayedURLOpens = nil;
}


- (void)applicationWillTerminate:(UIApplication *)application {
	// Save data if appropriate
    NSError *error;
    if (![[self managedObjectContext] save:&error])
        NSLog(@"[BlioAppAppDelegate applicationWillTerminate] Save failed with error: %@, %@", error, [error userInfo]);
    [self saveBookSnapshotIfAppropriate];
}

-(void)loginDismissed:(NSNotification*)note {
	NSLog(@"BlioAppAppDelegate loginDismissed: entered.");
	if ([[[note userInfo] valueForKey:@"sourceID"] intValue] == BlioBookSourceOnlineStore) {
		if ([[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore]) {
			[self.processingManager resumeProcessingForSourceID:BlioBookSourceOnlineStore];
			[[BlioStoreManager sharedInstance] retrieveBooksForSourceID:BlioBookSourceOnlineStore];
		}
		else {
			//			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"For Your Information...",@"\"For Your Information...\" Alert message title")
			//										 message:[NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"LOGIN_REQUIRED_FOR_UPDATING_PAID_BOOKS_VAULT",nil,[NSBundle mainBundle],@"Login is required to update your Archive. In the meantime, only previously synced books will display.",@"Alert message informing the end-user that login is required to update the Archive. In the meantime, previously synced books will display.")]
			//										delegate:self
			//							   cancelButtonTitle:@"OK"
			//							   otherButtonTitles:nil];			
		}
	}
}

#pragma mark -
#pragma mark UIApplicationDelegate - Background Tasks

-(void)applicationDidEnterBackground:(UIApplication *)application {
	NSLog(@"%@", NSStringFromSelector(_cmd));
    NSError *error;
    if (![[self managedObjectContext] save:&error])
        NSLog(@"[BlioAppAppDelegate applicationDidEnterBackground] Save failed with error: %@, %@", error, [error userInfo]);
    [self saveBookSnapshotIfAppropriate];
	[[NSUserDefaults standardUserDefaults] synchronize];
}
- (void)applicationWillEnterForeground:(UIApplication *)application {
	NSLog(@"%@", NSStringFromSelector(_cmd));	
}
- (void)applicationDidBecomeActive:(UIApplication *)application {
	NSLog(@"%@", NSStringFromSelector(_cmd));
	if (self.networkStatus != NotReachable) {
		if ([[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore] && ![[BlioStoreManager sharedInstance] storeHelperForSourceID:BlioBookSourceOnlineStore].isRetrievingBooks) {
			[[BlioStoreManager sharedInstance] retrieveBooksForSourceID:BlioBookSourceOnlineStore];
		}
	}		
}
- (void)applicationWillResignActive:(UIApplication *)application {
	NSLog(@"%@", NSStringFromSelector(_cmd));
}

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
		if ([[self.processingManager internetOperations] count] > 0)
		{
			// ALERT user to what just happened.
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Internet Connection Lost",@"\"Internet Connection Lost\" Alert message title")
										 message:NSLocalizedStringWithDefaultValue(@"INTERNET_ACCESS_LOST",nil,[NSBundle mainBundle],@"Current downloads have been interrupted. Downloads will resume automatically once internet access is restored.",@"Alert message informing the end-user that downloads in progress have been suspended due to lost internet access.")
										delegate:nil
							   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
							   otherButtonTitles:nil];
		}
		[self.processingManager stopInternetOperations];
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

#pragma mark -
#pragma mark State saving for restoration on launch.

- (void)saveBookSnapshotIfAppropriate
{
    BlioBookViewController *bookViewController = nil;
    for(UIViewController *potentialController in navigationController.viewControllers) {
        if([potentialController isKindOfClass:[BlioBookViewController class]]) {
            bookViewController = (BlioBookViewController *)potentialController;
        }
    }
    UIImage *pageImage = bookViewController.dimPageImage;
    if(pageImage) {
        [BlioDefaultViewController saveDynamicDefaultImage:pageImage];
    }
}

- (void)navigationController:(UINavigationController *)theNavigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated;
{
    if([viewController isKindOfClass:[BlioBookViewController class]]) {
        BlioBookViewController *bookViewController = (BlioBookViewController *)viewController;
        BlioBook *book = bookViewController.book;
        NSArray *toStore = [NSArray arrayWithObjects:book.sourceID, book.sourceSpecificID, nil];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:toStore forKey:kBlioOpenBookKey];
        [defaults synchronize];
    } else {
        BOOL containsBook = NO;
        for(UIViewController *potentialController in theNavigationController.viewControllers) {
            if([potentialController isKindOfClass:[BlioBookViewController class]]) {
                containsBook = NO;
            }
        }
        if(!containsBook) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults removeObjectForKey:kBlioOpenBookKey];
            [defaults synchronize];
        }
    }
}

@end

