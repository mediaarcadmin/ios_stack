//
//  MRGridViewController.h
//
//  Created by Sean Doherty on 3/10/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MRGridViewDataSource.h"
#import "MRGridViewDelegate.h"

@protocol MRGridViewDelegate,MRGridViewDataSource;
@interface MRGridViewController : UIViewController<MRGridViewDataSource,MRGridViewDelegate> {
	UIScrollView* scrollView;
	MRGridView* _gridView;
}
@property(readwrite,retain,nonatomic) MRGridView* gridView;
@property(readwrite,retain,nonatomic) UIScrollView* scrollView;

@end
