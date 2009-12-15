//
//  PaginateAppDelegate.m
//  HHGG
//
//  Created by James Montgomerie on 05/08/2009.
//  Copyright James Montgomerie 2009. All rights reserved.
//

#import "PaginateAppDelegate.h"
#import "PaginateRootViewController.h"


@implementation PaginateAppDelegate

@synthesize window;
@synthesize navigationController;


#pragma mark -
#pragma mark Application lifecycle

- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    
    // Override point for customization after app launch    
	
	[window addSubview:[navigationController view]];
    [window makeKeyAndVisible];
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

