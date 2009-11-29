//
//  TransitionTestAppDelegate.h
//  TransitionTest
//
//  Created by James Montgomerie on 29/11/2009.
//  Copyright Things Made Out Of Other Things 2009. All rights reserved.
//

@interface TransitionTestAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    UINavigationController *navigationController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

@end

