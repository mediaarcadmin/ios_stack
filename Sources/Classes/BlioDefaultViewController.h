//
//  BlioDefaultViewController.h
//  BlioApp
//
//  Created by James Montgomerie on 09/12/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BlioDefaultViewController : UIViewController {
    BOOL viewOnScreen;
    
    UIImage *dynamicDefault;
    UIInterfaceOrientation dynamicDefaultOrientation;
    
    UIImageView *dynamicImageView;
    UIImageView *nonDynamicImageView;
    
    BOOL fadesBegun;
}

+ (void)saveDynamicDefaultImage:(UIImage *)image;

- (void)fadeOutDefaultImageIfDynamicImageAlsoAvailable;
- (void)fadeOutCompletly;

@end
