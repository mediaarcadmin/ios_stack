//
//  TransitionTestAppDelegate.m
//  TransitionTest
//
//  Created by James Montgomerie on 29/11/2009.
//  Copyright Things Made Out Of Other Things 2009. All rights reserved.
//

#import "TransitionTestAppDelegate.h"
#import "TransitionTestRootViewController.h"


@implementation TransitionTestAppDelegate

@synthesize window;
@synthesize navigationController;


#pragma mark -
#pragma mark Application lifecycle

- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    
    // Override point for customization after app launch    
	
	[window addSubview:[navigationController view]];
    [window makeKeyAndVisible];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logNotification:) name:nil object:nil];
    
    
    
    
}

- (void)logNotification:(NSNotificationCenter *)note {
    NSLog(@"NOTIFICATIONNNNNN = %@", note);
}


- (void)applicationWillTerminate:(UIApplication *)application {
	// Save data if appropriate
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	[navigationController release];
	[window release];
	[super dealloc];
}


@end

