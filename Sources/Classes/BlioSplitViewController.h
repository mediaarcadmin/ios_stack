//
//  BlioSplitViewController.h
//
//  Created by Don Shin on 6/25/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioSplitView.h"

@protocol BlioSplitViewControllerDelegate;

@interface BlioSplitViewController : UIViewController {

		id                      _delegate;
		NSMutableArray          *_viewControllers;
		BlioSplitView * splitView;		
	}
	
@property(nonatomic,copy)       NSArray *viewControllers;  
@property(nonatomic,retain)       BlioSplitView *splitView;  
@property(nonatomic, assign)    id <BlioSplitViewControllerDelegate> delegate;
@end