//
//  MRGridViewDelegate.h
//
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//	Licensed to K-NFB Reading Technology, Inc. for use in the Blio iPhone OS Application.
//	Please refer to the Licensing Agreement for terms and conditions.

#import <UIKit/UIKit.h>
#import "MRGridView.h"

@class MRGridView;
@protocol MRGridViewDelegate <UIScrollViewDelegate>
@optional
-(void)gridView:(MRGridView *)gridView didSelectCellAtIndex:(NSInteger)index;
-(void)gridView:(MRGridView *)gridView confirmationForDeletionAtIndex:(NSInteger)index;
@end
