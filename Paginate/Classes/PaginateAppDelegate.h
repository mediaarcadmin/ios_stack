//
//  PaginateAppDelegate.h
//  HHGG
//
//  Created by James Montgomerie on 05/08/2009.
//  Copyright James Montgomerie 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PaginateAppDelegate : NSObject <UIApplicationDelegate> {
    
    UIWindow *window;
    UINavigationController *navigationController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

@end

