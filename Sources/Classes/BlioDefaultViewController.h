//
//  BlioDefaultViewController.h
//  BlioApp
//
//  Created by James Montgomerie on 09/12/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioAutorotatingViewController.h"

@interface BlioDefaultViewController : BlioAutorotatingViewController {
    BOOL viewOnScreen;
    
    UIImage *dynamicDefault;
    UIInterfaceOrientation dynamicDefaultOrientation;
    
    UIImageView *dynamicImageView;
    UIImageView *nonDynamicImageView;
    
    void(^doAfterFadeDefaultBlock)(void);
    void(^doAfterFadeOutCompletlyBlock)(void);
    
    BOOL fadesBegun;
}

+ (void)saveDynamicDefaultImage:(UIImage *)image;

- (void)fadeOutDefaultImageIfDynamicImageAlsoAvailableThenDo:(void(^)(void))doAfterwardsBlock;
- (void)fadeOutCompletlyThenDo:(void(^)(void))doAfterwardsBlock;

@end
