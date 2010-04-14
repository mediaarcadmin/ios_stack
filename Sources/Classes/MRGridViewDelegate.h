//
//  MRGridViewDelegate.h
//  scifi
//
//  Created by Sean Doherty on 3/20/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MRGridView.h"

@class MRGridView;
@protocol MRGridViewDelegate <UIScrollViewDelegate>
@optional
-(void)gridView:(MRGridView *)gridView didSelectCellAtIndex:(NSInteger)index;
@end
