//
//  BlioStoreTabViewController.h
//  BlioApp
//
//  Created by matt on 05/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioProcessing.h"

@interface BlioStoreTabViewController : UITabBarController <UITabBarControllerDelegate> {
    id <BlioProcessingDelegate> processingDelegate;
}

- (id)initWithProcessingDelegate:(id<BlioProcessingDelegate>)aProcessingDelegate;

@end
