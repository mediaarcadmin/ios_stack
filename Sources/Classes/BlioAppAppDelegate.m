//
//  BlioAppAppDelegate.m
//  BlioApp
//
//  Created by James Montgomerie on 16/12/2009.
//  Copyright Things Made Out Of Other Things 2009. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <libEucalyptus/EucSharedHyphenator.h>
#import <pthread.h>
#import "BlioAppAppDelegate.h"
#import "BlioLibraryViewController.h"
#import "BlioAlertManager.h"
#import "BlioStoreManager.h"
#import "BlioSocialManager.h"
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
#import "BlioWelcomeViewController.h"
#import "BlioAcapelaAudioManager.h"

@interface BlioAppAppDelegate ()

- (void)saveBookSnapshotIfAppropriate;
- (void)persistApplicationState;

- (void)delayedApplicationDidFinishLaunchingStep1:(UIApplication *)application;
- (void)delayedApplicationDidFinishLaunchingStep2:(UIApplication *)application;

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
    [BlioProcessingOperation addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:docsWmModelCert]];

	NSString* rsrcPRModelCert = [sourceDir stringByAppendingPathComponent:prModelCertFilename]; 
	NSString* docsPRModelCert = [documentsDirectory stringByAppendingPathComponent:prModelCertFilename];
	[fileManager copyItemAtPath:rsrcPRModelCert toPath:docsPRModelCert error:&err];    
    [BlioProcessingOperation addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:docsPRModelCert]];
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
		else {
            NSLog(@"Created TTS directory within Application Support...");
            [BlioProcessingOperation addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:voicesPath]];
        }
        
	}    
    
#ifdef TEST_MODE
	
    NSString *manualVoiceDestinationPath = [voicesPath stringByAppendingPathComponent:@"Acapela For iPhone LF USEnglish Tracy"];
	NSString *manualVoiceCopyPath = 
	[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Acapela For iPhone LF USEnglish Tracy"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:manualVoiceCopyPath] && ![[NSFileManager defaultManager] fileExistsAtPath:manualVoiceDestinationPath]) {
		NSError * manualVoiceCopyError = nil;
		if (![[NSFileManager defaultManager] copyItemAtPath:manualVoiceCopyPath toPath:manualVoiceDestinationPath error:&manualVoiceCopyError]) 
			NSLog(@"ERROR: could not manually copy the Tracy voice directory to the Documents/TTS directory! %@, %@",manualVoiceCopyError, [manualVoiceCopyError userInfo]);
		else NSLog(@"Copied Tracy into TTS directory...");
	}
    
#endif
	
	NSLog(@"voicesPath: %@",voicesPath);
	[AcapelaSpeech setVoicesDirectoryArray:[NSArray arrayWithObject:voicesPath]];    
}

- (void)resetDRM {
    // Delete the secure store.
    NSString *supportDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* strDataStore = [supportDirectory stringByAppendingString:@"/playready.hds"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:strDataStore]) {
        NSError * error;
        if (![[NSFileManager defaultManager] removeItemAtPath:strDataStore error:&error]) 
            NSLog(@"WARNING: deletion of PlayReady store failed. %@, %@", error, [error userInfo]);
    }
    
    // Delete device certificates. 
    NSString *devcertDatFile = [supportDirectory stringByAppendingPathComponent:@"devcert.dat"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:devcertDatFile]) {
        NSError * error;
        if (![[NSFileManager defaultManager] removeItemAtPath:devcertDatFile error:&error])
            NSLog(@"WARNING: deletion of device certificate failed. %@, %@", error, [error userInfo]);
    }
    NSString *binaryDevcertDatFile = [supportDirectory stringByAppendingPathComponent:@"bdevcert.dat"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:binaryDevcertDatFile]) {
        NSError * error;
        if (![[NSFileManager defaultManager] removeItemAtPath:binaryDevcertDatFile error:&error])
            NSLog(@"WARNING: deletion of binary device certificate failed. %@, %@", error, [error userInfo]);
    }
    
// uniqueIdentifier no longer available from 7.0 on
//#ifdef TEST_MODE
//    NSString* testDeviceID = [[[UIDevice currentDevice] uniqueIdentifier] stringByAppendingString:@"X"];
//    [[NSUserDefaults standardUserDefaults] setObject:testDeviceID forKey:kBlioDeviceIDDefaultsKey];
//#else
    // Reset the id for this device.  It must now be a UUID.
    CFUUIDRef uuidObj = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidStr = [(NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidObj) autorelease];
    [[NSUserDefaults standardUserDefaults] setObject:uuidStr forKey:kBlioDeviceIDDefaultsKey];
    CFRelease(uuidObj); 
//#endif
    
    // Reinitialize model certificates.
    // With KDRM no longer necessary.
    // [self ensureCorrectCertsAvailable];
}

-(void)forceRedownload {
    [BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Library Update",@"\"Library Update\" alert message title")
                                 message:NSLocalizedStringWithDefaultValue(@"DRM_RESET",nil,[NSBundle mainBundle],@"This version of Blio requires an initial redownload of your paid and borrowed books.  You can retrieve them by going to your Archive.",@"Alert Text informing the end user that books must be redownloaded.")
                                delegate:nil
                       cancelButtonTitle:nil
                       otherButtonTitles:@"OK", nil];
    [self resetDRM]; 
    [self.processingManager deleteBooksForSourceID:BlioBookSourceOnlineStore];
    // For the convenience of upgraders we do not force a login.
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kBlioHasLoggedInKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)checkForBackup {
    // check for backup flag file
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString * flagFilePath = [basePath stringByAppendingPathComponent: @"NotFromBackup"];
    
    BOOL flagFileMissing = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:flagFilePath]) {
        // possibly restored, maybe first time...
        flagFileMissing = YES;
        // create flag file for future
        [[NSFileManager defaultManager] createFileAtPath:flagFilePath
                                                contents:[NSData data]
                                              attributes:nil];
        NSURL *flagFileURL = [NSURL fileURLWithPath: flagFilePath];
        [BlioProcessingOperation addSkipBackupAttributeToItemAtURL:flagFileURL];
    }
    
    NSString* deviceIDDefaults = [[NSUserDefaults standardUserDefaults] stringForKey:kBlioDeviceIDDefaultsKey];
    // For test mode we don't have a way of detecting an upgrade so we skip all this.  
    // So to test the following, don't be in test mode.
    if ([deviceIDDefaults length] == 40) {  
        // We are upgrading from 3.1 or previous, or else restoring from version 3.1 backed up to iTunes.
        [self forceRedownload];
        return YES;
    }
    else if (flagFileMissing) {
        // We have installed fresh, or else restoring from version 3.2 that's been backed up either 
        // to iTunes and iCloud. 
        [self resetDRM];
        [[BlioStoreManager sharedInstance] logoutForSourceID:BlioBookSourceOnlineStore];
        if (deviceIDDefaults) {
            // NSUserDefaults happened to be backed up and restored
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kBlioHasLoggedInKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        NSManagedObjectContext *moc = [self managedObjectContext];
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"BlioBook" inManagedObjectContext:moc]];
        //        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"sourceID == %@",[NSNumber numberWithInt:BlioBookSourceOnlineStore]]];
        NSError *errorExecute = nil; 
        NSArray *results = [moc executeFetchRequest:fetchRequest error:&errorExecute]; 
        [fetchRequest release];
        if(!errorExecute && results.count != 0) {
            // we've restored: no flag file, but there are books in the persistent store. Reset DRM and make paid books "placeholder only" in preparation for re-downloading. Verify bundled books.
            [BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Rights Management Reset",@"\"Rights Management Reset\" alert message title") 
                                         message:NSLocalizedStringWithDefaultValue(@"DRM_RESET_AFTER_RESTORE",nil,[NSBundle mainBundle],@"This version of Blio was restored from another device.  You must log in to redownload your purchased books.  Remember to deregister your old device if you no longer plan to use Blio on it.",@"Alert Text informing the end user that login is required for paid books to be redownloaded.")
                                        delegate:nil 
                               cancelButtonTitle:nil
                               otherButtonTitles:@"OK", nil];
            
            [self.processingManager verifyBundledBooks];
            [self.processingManager deleteBooksForSourceID:BlioBookSourceOnlineStore];
            forceLoginAfterRestore = YES;
        }
    }
    return NO;
}

- (BOOL) checkVersion {
    NSLog(@"Current app version number: %@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]);
    NSDecimalNumber * appVersionNumber = [NSDecimalNumber decimalNumberWithString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    id prevVersion = [[NSUserDefaults standardUserDefaults] objectForKey:@"PreviouslyLaunchedAppVersion"];
    if (!prevVersion) {
        [[NSUserDefaults standardUserDefaults] setObject:appVersionNumber forKey:@"PreviouslyLaunchedAppVersion"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        // since the first version to record LastLaunchedVersionNumber also happens to be the first version to use the new TTS engine, we also delete old TTS voices if present
        if ([[[BlioAcapelaAudioManager sharedAcapelaAudioManager]  availableVoicesForUse] count] > 0) {
            // prompt end-user to re-download voices
            [[BlioAcapelaAudioManager sharedAcapelaAudioManager] promptRedownload];
        }
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"WelcomeScreenShown"]) {
            // Installing over a version to old to have stored a PreviouslyLaunchedAppVersion,
            // and has been launched at least once.
            [self forceRedownload];
            return YES;
        }
        
    }
    else if ([(NSNumber*)prevVersion floatValue] < [appVersionNumber floatValue]) {
        [[NSUserDefaults standardUserDefaults] setObject:appVersionNumber forKey:@"PreviouslyLaunchedAppVersion"];
        [[NSUserDefaults standardUserDefaults] synchronize];
#ifndef TOSHIBA
        // If the previous version is on PlayReady, force a switch to KDRM.
        if ( [(NSNumber*)prevVersion floatValue] <= 3.6 ) {
            [self forceRedownload];
            return YES;
        }
#endif
    }
    return NO;
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
    defaultImageViewController = [[BlioDefaultViewController alloc] initWithNibName:nil bundle:nil];
    self.window.rootViewController = defaultImageViewController;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Avoids CFURLCache crash in 6.1.
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
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
    return [[BlioSocialManager sharedSocialManager].facebook handleOpenURL:url]; 
}


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	return [self application:application handleOpenURL:url];
}


- (void)delayedApplicationDidFinishLaunchingStep1:(UIApplication *)application {
    // Now that the view is loaded, and in the correct orientation, show the
    // book page if one was available.
    [defaultImageViewController fadeOutDefaultImageIfDynamicImageAlsoAvailableThenDo:^{
        [self delayedApplicationDidFinishLaunchingStep2:application];
    }];
}

- (void)delayedApplicationDidFinishLaunchingStep2:(UIApplication *)application {
    [self performBackgroundInitialisation];
    
    [[NSBundle mainBundle] loadNibNamed:@"MainNavControllerAndLibraryView" owner:self options:nil];
    
    NSError * audioError = nil;
	if (![[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&audioError]) {
		NSLog(@"[ERROR: could not set AVAudioSessionCategory with error: %@, %@", audioError, [audioError userInfo]);
	} else {
        AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(UInt32), (UInt32[]){1});
    }
    
    [self ensureApplicationSupportAvailable];
    
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
	
	[BlioStoreManager sharedInstance].rootViewController = navigationController;
	[BlioSocialManager sharedSocialManager].rootViewController = navigationController;
	[BlioAcapelaAudioManager sharedAcapelaAudioManager].rootViewController = navigationController;
	
	BOOL forcedRedownload = [self checkForBackup];
    if ( !forcedRedownload )
        forcedRedownload = [self checkVersion];
	   
    BOOL openedBook = NO;
    if ( !forcedRedownload ) {

        NSArray *openBookIDs = [[NSUserDefaults standardUserDefaults] objectForKey:kBlioOpenBookKey];
        if (openBookIDs.count == 2) {
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
            [fetchRequest setEntity:[NSEntityDescription entityForName:@"BlioBook" inManagedObjectContext:moc]];
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"sourceID == %@ && sourceSpecificID == %@",
                                        [openBookIDs objectAtIndex:0],
                                        [openBookIDs objectAtIndex:1]]];
            NSError *errorExecute = nil; 
            NSArray *results = [moc executeFetchRequest:fetchRequest error:&errorExecute]; 
            [fetchRequest release];
            if(!errorExecute && results.count == 1) {
                if ([[results objectAtIndex:0] isEncrypted]) {
                    if ([[results objectAtIndex:0] decryptionIsAvailable]) {
                        [libraryController openBook:[results objectAtIndex:0]];
                        openedBook = YES;
                    }
                }
                else {
                    [libraryController openBook:[results objectAtIndex:0]];
                    openedBook = YES;
                }
            }
        }
    }
    
    BOOL animationsWereEnabled = [UIView areAnimationsEnabled];
    [UIView setAnimationsEnabled:NO];
    window.rootViewController = navigationController;
    [window addSubview:defaultImageViewController.view];
    [window sendSubviewToBack:navigationController.view];
    [UIView setAnimationsEnabled:animationsWereEnabled];
    
    [defaultImageViewController fadeOutCompletlyThenDo:^{
        
        // this login block must happen after the views are attached to the window
        [[BlioStoreManager sharedInstance] retrieveToken];
        if (![[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore]) {
            if (forceLoginAfterRestore) {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDismissedAfterCloudRestore:) name:BlioLoginFinished object:[BlioStoreManager sharedInstance]];
                [[BlioStoreManager sharedInstance] requestLoginForSourceID:BlioBookSourceOnlineStore];
            }
            else {
                [BlioStoreManager sharedInstance].initialLoginCheckFinished = YES;
            }
        }
        else {
            [BlioStoreManager sharedInstance].initialLoginCheckFinished = YES;
//          [[BlioStoreManager sharedInstance] retrieveBooksForSourceID:BlioBookSourceOnlineStore];
        }
        
        [self.processingManager resumeProcessing];
        
        
        self.delayedDidFinishLaunchingLaunchComplete = YES;
        
        for(NSURL *url in self.delayedURLOpens) {
            [self application:[UIApplication sharedApplication] handleOpenURL:url];
        }
        self.delayedURLOpens = nil;
        
        id welcomeScreenShown = [[NSUserDefaults standardUserDefaults] objectForKey:@"WelcomeScreenShown"];
        if (!welcomeScreenShown) {
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"WelcomeScreenShown"]; 
            [[NSUserDefaults standardUserDefaults] synchronize];
             if (!forceLoginAfterRestore)
                 [[BlioStoreManager sharedInstance] showWelcomeViewForSourceID:BlioBookSourceOnlineStore];
        }
        [defaultImageViewController release];
        defaultImageViewController = nil;
    }];
    
    if(!openedBook) {
        [self performSelector:@selector(switchStatusBar) withObject:nil afterDelay:0];
    }
}

-(void)loginDismissed:(NSNotification*)note {
//	NSLog(@"BlioAppAppDelegate loginDismissed: entered.");
	[BlioStoreManager sharedInstance].initialLoginCheckFinished = YES;
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioLoginFinished object:[BlioStoreManager sharedInstance]];
	if ([[[note userInfo] valueForKey:@"sourceID"] intValue] == BlioBookSourceOnlineStore) {
		if ([[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore]) {
//			[self.processingManager resumeProcessingForSourceID:BlioBookSourceOnlineStore];
//			[[BlioStoreManager sharedInstance] retrieveBooksForSourceID:BlioBookSourceOnlineStore];
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
-(void)loginDismissedAfterCloudRestore:(NSNotification*)note {
	[BlioStoreManager sharedInstance].initialLoginCheckFinished = YES;
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioLoginFinished object:[BlioStoreManager sharedInstance]];
	if ([[[note userInfo] valueForKey:@"sourceID"] intValue] == BlioBookSourceOnlineStore) {
		if (![[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore]) {
            [self.processingManager deletePaidBooks];
        }
    }
}
#pragma mark -
#pragma mark UIApplicationDelegate - Background Tasks and Termination

- (void)persistApplicationState {
    NSError *error;
    if (![[self managedObjectContext] save:&error])
        NSLog(@"[BlioAppAppDelegate applicationWillTerminate] Save failed with error: %@, %@", error, [error userInfo]);
	[[NSUserDefaults standardUserDefaults] synchronize];
    [self saveBookSnapshotIfAppropriate];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[self persistApplicationState];
}

-(void)applicationDidEnterBackground:(UIApplication *)application {
	[self persistApplicationState];
}
- (void)applicationWillEnterForeground:(UIApplication *)application {
	NSLog(@"%@", NSStringFromSelector(_cmd));	
}
- (void)applicationDidBecomeActive:(UIApplication *)application {
//	NSLog(@"%@", NSStringFromSelector(_cmd));
	// this logic happens to only execute for subsequent applicationDidBecomeActive invocations beyond the first time (effectively never for iOS 3.2)
	if (self.networkStatus != NotReachable) {
		if ([[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore] && ![[BlioStoreManager sharedInstance] storeHelperForSourceID:BlioBookSourceOnlineStore].isRetrievingBooks) {
			[[BlioStoreManager sharedInstance] retrieveBooksForSourceID:BlioBookSourceOnlineStore];
		}
	}		
}
- (void)applicationWillResignActive:(UIApplication *)application {
	NSLog(@"%@", NSStringFromSelector(_cmd));
    // Avoids CFURLCache crash in 6.1.
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
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
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Internet Connection Error",@"\"Internet Connection Error\" Alert message title")
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
//    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain]; 
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Blio" ofType:@"momd"];
    NSURL *momURL = [NSURL fileURLWithPath:path];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
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
	
    // for automatic lightweight migration
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];

    
	NSError *error;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
        // Handle error
        
        NSLog(@"ERROR: persistent store was not added to Coordinator! Description: %@",[error localizedDescription]);
        
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

#pragma mark - 
#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (buttonIndex == 0) {

	}
	else if (buttonIndex == 1) {
        [self.libraryController showStore:alertView];
	}
}

@end

