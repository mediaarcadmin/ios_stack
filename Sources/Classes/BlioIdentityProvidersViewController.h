//
//  BlioIdentityProvidersViewController.h
//  StackApp
//
//  Created by Arnold Chien on 1/28/14.
//  Copyright (c) 2014 Arnold Chien. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioAutorotatingViewController.h"

@interface BlioIdentityProvidersViewController : BlioAutorotatingTableViewController {
    NSMutableArray* images;
    NSMutableArray* names;
    NSArray *identityProviders;
}

@property (nonatomic, retain) NSArray *identityProviders;

- (id)initWithProviders:(NSMutableArray*)providers;

@end
