//
//  BlioAlwaysModalPopoverController.m
//  BlioApp
//
//  Created by matt on 06/09/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioModalPopoverController.h"


@implementation BlioModalPopoverController

// This stops the automatic addition of the UIToolbar when displaying from a UIBarButtonItem
- (void)setPassthroughViews:(NSArray *)newArray {
    [super setPassthroughViews:[NSArray array]];
}

@end
