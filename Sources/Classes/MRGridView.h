//
//  MRGridView.h
//
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//	Licensed to K-NFB Reading Technology, Inc. for use in the Blio iPhone OS Application.
//	Please refer to the Licensing Agreement for terms and conditions.

#import <UIKit/UIKit.h>
#import "MRGridViewDataSource.h"
#import "MRGridViewDelegate.h"
#import "MRGridViewCell.h"

typedef enum {
	MRGridViewCellAnimationFade
} MRGridViewCellAnimation;

@protocol MRGridViewDelegate, MRGridViewDataSource;

static const NSInteger MRGridViewMoveStyleDisplace = 0;
static const NSInteger MRGridViewMoveStyleMarker = 1;
static const CGFloat MRGridViewDragScrollSpeed = 10.0;
static const CGFloat MRGridViewScrollOverlapHeight = 44.0;

@interface MRGridView : UIScrollView<UIScrollViewDelegate> {
	id<MRGridViewDataSource> gridDataSource;
	id<MRGridViewDelegate> gridDelegate;
	NSMutableDictionary* reusableCells;
	UIView* gridView;
	CGSize currCellSize;
	CGFloat minimumBorderSize;
	CGFloat currBorderSize;
	NSInteger numCellsInRow;
	MRGridViewCell* currDraggedCell;
	NSInteger currDraggedCellIndex;
	CGPoint currDraggedCellOriginalCenter;
	UIView* shadowView;
	UIView* markerView;
	NSInteger currentHoveredIndex;
	NSMutableDictionary * cellIndices;
	NSTimer * scrollTimer;
	NSTimer * editTimer;
	CGPoint lastTouchLocation;
	CGFloat scrollIntensity;
	UITouch * _activeTouch;
	NSInteger _keyValueOfCellToBeDeleted;

	//this is a temporary way of keeping track of what row we are on
	NSInteger highestCellYValue;
	NSInteger lowestCellYValue;
	CGPoint currentScrollOffset;
	NSInteger moveStyle;
	BOOL cellDragging;
	float cellPrePickupAlpha;
	
	BOOL editing;
}

@property(readwrite,assign,nonatomic) id<MRGridViewDataSource> gridDataSource;
@property(readwrite,assign,nonatomic) id<MRGridViewDelegate> gridDelegate;
@property(readwrite,assign,nonatomic) MRGridViewCell* currDraggedCell;
@property(readwrite,retain,nonatomic) NSMutableDictionary * reusableCells;
@property(readwrite,retain,nonatomic) NSMutableDictionary * cellIndices;
@property(readwrite,assign,nonatomic) CGPoint currentScrollOffset;
@property(readwrite,assign,nonatomic) NSInteger moveStyle;
@property(readwrite,nonatomic, getter = isEditing) BOOL editing;

- (void)reloadData;
- (void)rearrangeCells;
- (MRGridViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;

-(void) updateSize;
-(CGRect) frameForCellAtGridIndex: (NSInteger) index;
-(MRGridViewCell*) cellAtGridIndex: (NSInteger) index;
-(NSInteger)rowCount;
- (void)handleSingleTap:(CGPoint)touchLoc;
-(NSInteger) indexForTouchLocation:(CGPoint)touchLoc;
-(void) setCellSize:(CGSize)size withBorderSize:(NSInteger) borderSize;
-(void) calculateColumnCount;
- (void) addCellAtIndex:(NSInteger)cellIndex;
- (void) removeCellAtIndex:(NSInteger)cellIndex;
- (void)enqueueReusableCell: (MRGridViewCell*) cell withIdentifier:(NSString *)identifier;
- (MRGridViewCell*)dequeueReusableCellWithIdentifier:(NSString *)identifier;
-(void)scrollIfNeededAtPosition:(NSTimer*)aTimer;
-(void)animateCellPickupForCell:(MRGridViewCell*)cell;
-(void)animateCellPutdownForCell:(MRGridViewCell*)cell toLocation:(CGPoint)theLocation;
-(void)cleanupAfterCellDrop;
-(NSInteger) indexForTouchLocation:(CGPoint)touchLoc;
-(NSArray*) indexesForCellsInRect:(CGRect)rect;
-(void) putMarkerAtNearestSpace:(CGPoint)touchLoc;
-(UIView*) viewAtLocation:(CGPoint)touchLoc;
-(void)deleteIndices:(NSArray*)indices withCellAnimation:(MRGridViewCellAnimation)cellAnimation;

- (void)setEditing:(BOOL)editingVal animated:(BOOL)animate;

-(void)accessibilityFocusedOnCell:(id)object;

@end
