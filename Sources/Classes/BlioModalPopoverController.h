//
//  BlioAlwaysModalPopoverController.h
//  BlioApp
//
//  Created by matt on 06/09/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BlioModalPopoverController : UIPopoverController {

}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation;    

@end
