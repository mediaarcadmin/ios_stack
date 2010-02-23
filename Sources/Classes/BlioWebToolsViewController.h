//
//  BlioWebToolsViewController.h
//  BlioApp
//
//  Created by matt on 23/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BlioWebToolsViewController : UINavigationController {
    BOOL statusBarHiddenOnEntry;
}

- (id)initWithURL:(NSURL *)url;

@end
