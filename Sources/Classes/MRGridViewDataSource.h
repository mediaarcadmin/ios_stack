//
//  MRGridViewDataSource.h
//
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//	Licensed to K-NFB Reading Technology, Inc. for use in the Blio iPhone OS Application.
//	Please refer to the Licensing Agreement for terms and conditions.

#import <UIKit/UIKit.h>
#import "MRGridView.h"
#import "MRGridViewCell.h"

@class MRGridView,MRGridViewCell;

@protocol MRGridViewDataSource <NSObject>

-(MRGridViewCell*)gridView:(MRGridView*)gridView cellForGridIndex: (NSInteger)index;
-(NSInteger)numberOfItemsInGridView:(MRGridView*)gridView;
-(NSString*)contentDescriptionForCellAtIndex:(NSInteger)index;
-(BOOL) gridView:(MRGridView*)gridView canMoveCellAtIndex: (NSInteger)index;
-(void) gridView:(MRGridView*)gridView moveCellAtIndex: (NSInteger)fromIndex toIndex: (NSInteger)toIndex;
-(void) gridView:(MRGridView*)gridView finishedMovingCellToIndex:(NSInteger)toIndex;
-(void) gridView:(MRGridView*)gridView commitEditingStyle:(MRGridViewCellEditingStyle)editingStyle forIndex:(NSInteger)index;

@end
