//
//  MRGridViewController.h
//
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//	Licensed to K-NFB Reading Technology, Inc. for use in the Blio iPhone OS Application.
//	Please refer to the Licensing Agreement for terms and conditions.

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
