//
//  MRGridViewDataSource.h
//  scifi
//
//  Created by Sean Doherty on 3/20/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MRGridView.h"
#import "MRGridViewCell.h"

@class MRGridView,MRGridViewCell;

@protocol MRGridViewDataSource <NSObject>

-(MRGridViewCell*)gridView:(MRGridView*)gridView cellForGridIndex: (NSInteger)index;
-(NSInteger)numberOfItemsInGridView:(MRGridView*)gridView;
-(void) gridView:(MRGridView*)gridView moveCellAtIndex: (NSInteger)fromIndex toIndex: (NSInteger)toIndex;

@end
