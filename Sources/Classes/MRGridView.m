//
//  MRGridView.m
//
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//	Licensed to K-NFB Reading Technology, Inc. for use in the Blio iPhone OS Application.
//	Please refer to the Licensing Agreement for terms and conditions.

#import "MRGridView.h"

@interface MRGridView (PRIVATE)
- (void)invalidateScrollTimer;
- (void)invalidateEditTimer;
-(void) resetEditTimer;
-(void) resetScrollTimer;
@end

@implementation MRGridView
@synthesize gridDataSource, gridDelegate, currDraggedCell,currentScrollOffset,reusableCells,cellIndices,editing,moveStyle;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
		[self setBouncesZoom:YES];
		[self setScrollEnabled:YES];
		self.autoresizingMask = (UIViewAutoresizingFlexibleHeight|
								 UIViewAutoresizingFlexibleWidth);	
		
		gridView = [[UIView alloc]initWithFrame:frame];
		gridView.autoresizingMask = (UIViewAutoresizingFlexibleWidth
									 );	
		self.delegate = self;
		reusableCells = [[NSMutableDictionary dictionary]retain];
		cellIndices = [[NSMutableDictionary dictionary]retain];
		[self addSubview:gridView];
		moveStyle = MRGridViewMoveStyleDisplace;
		currDraggedCell = nil;
		currDraggedCellIndex = -1;
		currentHoveredIndex = -1;
		minimumBorderSize = 0;
		cellDragging = NO;
		scrollTimer = nil;
		_activeTouch = nil;
	}
    return self;
}

-(void)accessibilityFocusedOnCell:(id)object {
	//		NSLog(@"[BlioLibraryGridView accessibilityFocusedOnCell entered REPETITIVELY. object: %@",((BlioLibraryGridViewCell*)object).book.title);
	NSArray * indexes = [self indexesForCellsInRect:[object frame]];
	NSInteger rowIndex = -1;
	//		NSLog(@"[[indexes objectAtIndex:0] intValue]: %i",[[indexes objectAtIndex:0] intValue]);
	if (indexes && [indexes count] > 1) rowIndex = floor([[indexes objectAtIndex:0] intValue]/numCellsInRow);
	//		NSLog(@"rowIndex: %i",rowIndex);
	CGFloat newContentOffsetY = (currCellSize.height+currBorderSize)*(rowIndex) + currCellSize.height/2 - self.frame.size.height/2;
	//		NSLog(@"newContentOffsetY before: %f",newContentOffsetY);
	if (newContentOffsetY < 0) newContentOffsetY = 0;
	else if (newContentOffsetY > (self.contentSize.height - self.frame.size.height)) newContentOffsetY = (self.contentSize.height - self.frame.size.height);
	//		NSLog(@"newContentOffsetY: %f",newContentOffsetY);
	self.contentOffset = CGPointMake(self.contentOffset.x,newContentOffsetY);
	
    // In OS 4.0 we should check if voice-over is active before sending this notification
    // UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
	//    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
	
}

- (void) addCellAtIndex:(NSInteger)cellIndex {
//	NSLog(@"addCellAtIndex: %i",cellIndex);
//	NSLog(@"cellIndices count: %i, subviews count: %i",[cellIndices count],[[gridView subviews] count]);
	NSInteger protectedCellIndex = currDraggedCellIndex;
	if (moveStyle == MRGridViewMoveStyleDisplace) protectedCellIndex = currentHoveredIndex;
	if (cellIndex >=0 && cellIndex < [gridDataSource numberOfItemsInGridView:self] && cellIndex != protectedCellIndex)
	{
		if ([cellIndices objectForKey:[NSNumber numberWithInt:cellIndex]]) {
			[self removeCellAtIndex:cellIndex];
		}
		MRGridViewCell * gridCell = [gridDataSource gridView:self cellForGridIndex:cellIndex];
		[cellIndices setObject:gridCell forKey:[NSNumber numberWithInt:cellIndex]];
		[gridCell.deleteButton addTarget:self action:@selector(deleteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		if (self.isEditing) gridCell.deleteButton.alpha = 1;
		else gridCell.deleteButton.alpha = 0;
		[gridView addSubview:gridCell];
		[gridView sendSubviewToBack:gridCell]; // we do this so that the cell will by default be "behind" a dragged cell.
	}
//	NSLog(@"post-add cellIndices count: %i",[cellIndices count]);

}
- (void) removeCellAtIndex:(NSInteger)cellIndex {
//	NSLog(@"removeCellAtIndex: %i",cellIndex);
//	NSLog(@"cellIndices count: %i, subviews count: %i",[cellIndices count],[[gridView subviews] count]);
	MRGridViewCell * cell = nil;
	cell = [cellIndices objectForKey:[NSNumber numberWithInt:cellIndex]];
	if (cell != nil) {
//		NSLog(@"removing cell from view and adding to queue...");
		[cell retain];
		[cellIndices removeObjectForKey:[NSNumber numberWithInt:cellIndex]];
		if (cell != currDraggedCell) {
			[cell removeFromSuperview];
			[self enqueueReusableCell:cell withIdentifier:cell.reuseIdentifier];
		}
		[cell release];
	}	
//	NSLog(@"post-remove cellIndices count: %i",[cellIndices count]);
}
-(void)deleteButtonPressed:(id)sender {
	UIButton * deleteButton = (UIButton*)sender;
	MRGridViewCell * gridCell = (MRGridViewCell*)[deleteButton superview];
	NSArray *keys = [cellIndices allKeysForObject:gridCell];
	if ([keys count] > 1) NSLog(@"WARNING: multiple keys found in cellIndices for cell to be deleted!");
	else if ([keys count] == 0) NSLog(@"WARNING: No key found in cellIndices for cell to be deleted!");
	else {
		_keyValueOfCellToBeDeleted = [[keys objectAtIndex:0] intValue];
		if ([gridDelegate respondsToSelector:@selector(gridView:confirmationForDeletionAtIndex:)]) [gridDelegate gridView:self confirmationForDeletionAtIndex:_keyValueOfCellToBeDeleted];
		else [self.gridDataSource gridView:self commitEditingStyle:MRGridViewCellEditingStyleDelete forIndex:_keyValueOfCellToBeDeleted];
	}
}

//reloads data from dataSource
- (void)reloadData{
//	NSLog(@"MRGridView reloadData");
//	NSLog(@"cellIndices count: %i, subviews count: %i",[cellIndices count],[[gridView subviews] count]);
	[self cleanupAfterCellDrop];
	NSMutableArray * keys = [NSMutableArray array];
	for (id key in cellIndices)
	{
		[keys addObject:key];
	}
	for (int i = 0; i < [keys count];i++)
	{
		NSNumber * numberKey = [keys objectAtIndex:i];
		[self removeCellAtIndex:[numberKey intValue]];
		
	}
	for (UIView * view in [gridView subviews])
	{
		[view removeFromSuperview];
	}
//	NSLog(@"self bounds: %f,%f,%f,%f",[self bounds].origin.x,[self bounds].origin.y,[self bounds].size.width,[self bounds].size.height);
	NSArray * cellIndexes = [self indexesForCellsInRect:[self bounds]];
	for (NSNumber* index in cellIndexes){
//		NSLog(@"new cellIndexes: %i",[index intValue]);
		[self addCellAtIndex:[index intValue]];
	}
	[self updateSize];
}

- (void)rearrangeCells{
//	NSLog(@"MRGridView rearrangeCells");
//	NSLog(@"cellIndices count: %i, subviews count: %i",[cellIndices count],[[gridView subviews] count]);
	// rearranges cells that belong in the visible frame and refraining from accessing the data source as much as possible
	NSArray * cellIndexes = [self indexesForCellsInRect:[self bounds]];
	NSMutableArray * keys = [NSMutableArray array];
	for (id key in cellIndices)
	{
		[keys addObject:key];
	}
	// purge cells that do not belong in the visible frame.
	[UIView beginAnimations:@"rearrangeCells" context:nil];
//	NSLog(@"self bounds: %f,%f,%f,%f",[self bounds].origin.x,[self bounds].origin.y,[self bounds].size.width,[self bounds].size.height);
	for (int i = 0; i < [keys count];i++)
	{
		NSNumber * numberKey = [keys objectAtIndex:i];
//		NSLog(@"[numberKey intValue]: %i",[numberKey intValue]);
		if (!CGRectIntersectsRect([self frameForCellAtGridIndex:[numberKey intValue]],[self bounds]) || [numberKey intValue] >= [gridDataSource numberOfItemsInGridView:self]) {
			[self removeCellAtIndex:[numberKey intValue]];
//			NSLog(@"did NOT intersect");
		}
		else {
//			NSLog(@"DID intersect");
//			NSLog(@"currentHoveredIndex: %i",currentHoveredIndex);
//			NSLog(@"currDraggedCell: %@",currDraggedCell);
//			NSLog(@"[self cellAtGridIndex:[numberKey intValue]]: %@",[self cellAtGridIndex:[numberKey intValue]]);
			
			if (currentHoveredIndex != [numberKey intValue] && [self cellAtGridIndex:[numberKey intValue]] != currDraggedCell) {
//				NSLog(@"resetting frame for cell...");
				[self cellAtGridIndex:[numberKey intValue]].frame = [self frameForCellAtGridIndex:[numberKey intValue]];
			}
		}
	}
	for (NSNumber* index in cellIndexes){
		//		NSLog(@"new cellIndexes: %i",[index intValue]);
		if (![self cellAtGridIndex:[index intValue]]) {
//			NSLog(@"adding cell for index: %i", [index intValue]);
			[self addCellAtIndex:[index intValue]];
			[self cellAtGridIndex:[index intValue]].frame = [self frameForCellAtGridIndex:[index intValue]];
		}
	}
	[UIView commitAnimations];
	[self updateSize];
}


- (void)enqueueReusableCell: (MRGridViewCell*) cell withIdentifier:(NSString *)identifier{
//	NSLog(@"enqueueReusableCell");
//	NSLog(@"cellIndices count: %i, subviews count: %i",[cellIndices count],[[gridView subviews] count]);
	if (identifier != nil) {
		NSMutableArray* reusableCellsForIdentifier = (NSMutableArray*)[reusableCells objectForKey:identifier];
		if (reusableCellsForIdentifier == nil)
			reusableCellsForIdentifier = [NSMutableArray array];
		[reusableCellsForIdentifier addObject:cell];
		[reusableCells setObject:reusableCellsForIdentifier forKey:identifier];
	}
//	NSLog(@"post cellIndices count: %i",[cellIndices count]);
}

- (MRGridViewCell*)dequeueReusableCellWithIdentifier:(NSString *)identifier{
//	NSLog(@"dequeueReusableCellWithIdentifier");
//	NSLog(@"cellIndices count: %i, subviews count: %i",[cellIndices count],[[gridView subviews] count]);
	MRGridViewCell* gridCell = nil;
	NSMutableArray* reusableCellsForIdentifier = (NSMutableArray*)[reusableCells objectForKey:identifier];
	if (reusableCellsForIdentifier && [reusableCellsForIdentifier count] > 0){
		gridCell = [reusableCellsForIdentifier objectAtIndex:0];
		if (gridCell){
			[gridCell retain];
			[reusableCellsForIdentifier removeObjectAtIndex:0];
			[gridCell prepareForReuse];
			[gridCell autorelease];
		}
	}
//	NSLog(@"post cellIndices count: %i",[cellIndices count]);
	return gridCell;
}
-(MRGridViewCell*) cellAtGridIndex: (NSInteger) index {
	MRGridViewCell * gridCell = [cellIndices objectForKey:[NSNumber numberWithInt:index]];
	return gridCell;
}
//scroll view delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	// NOTE: would it have been faster to get the indexes for the old rectangle, get the indexes for the new rectangle, and compare the new arrays? we should test performance.
	CGFloat newScrollOffsetY = scrollView.contentOffset.y;
	CGFloat oldScrollOffsetY = self.currentScrollOffset.y;
	
	CGFloat oldRowsAbove = floor((oldScrollOffsetY-currBorderSize)/(currCellSize.height+currBorderSize));
	CGFloat newRowsAbove = floor((newScrollOffsetY-currBorderSize)/(currCellSize.height+currBorderSize));
	
	CGFloat oldRowsBelow = ceil((oldScrollOffsetY-currBorderSize+self.bounds.size.height)/(currCellSize.height+currBorderSize));
	CGFloat newRowsBelow = ceil((newScrollOffsetY-currBorderSize+self.bounds.size.height)/(currCellSize.height+currBorderSize));
	
	// recycle first
	NSInteger recycleRowDelta = 0;
	NSInteger recycleRowStart = 0;
	NSInteger createRowDelta = 0;
	NSInteger createRowStart = 0;
	if (newScrollOffsetY > oldScrollOffsetY) { // we're scrolling down
		recycleRowDelta = newRowsAbove - oldRowsAbove;
		recycleRowStart = oldRowsAbove;
		createRowDelta = newRowsBelow - oldRowsBelow;
		createRowStart = oldRowsBelow;
	}
	else if (newScrollOffsetY < oldScrollOffsetY) {
		recycleRowDelta = oldRowsBelow - newRowsBelow;
		recycleRowStart = newRowsBelow;
		createRowDelta = oldRowsAbove - newRowsAbove;
		createRowStart = newRowsAbove;
	}
	else return;
	
	if (abs(newScrollOffsetY - oldScrollOffsetY) >= self.bounds.size.height) {
		// total refresh - recycle all cells
		NSArray * cellIndexes = [self indexesForCellsInRect:CGRectMake(0, 0+oldScrollOffsetY, self.bounds.size.width, self.bounds.size.height)];
		for (NSNumber * index in cellIndexes) {
			[self removeCellAtIndex:[index intValue]];
		}
	}
	else if (recycleRowDelta > 0) {
		// we've lost at least one row
		for (int i = recycleRowStart; i < recycleRowStart+recycleRowDelta; i++)
		{
			// recycle each row
			for (int j = 0; j < numCellsInRow;j++)
			{
				// recycle cell # i*[self numCellsInRow]+j --- check to make sure it actually exists!!! (e.g. incomplete row)
				[self removeCellAtIndex:((i*numCellsInRow)+j)];
			}
		}
	}
	
	// now make sure the right cells are visible
	if (abs(newScrollOffsetY - oldScrollOffsetY) >= self.bounds.size.height) {
		// total refresh - create all cells
		NSArray * cellIndexes = [self indexesForCellsInRect:CGRectMake(0, 0+newScrollOffsetY, self.bounds.size.width, self.bounds.size.height)];
		for (NSNumber* index in cellIndexes){
			if (![self cellAtGridIndex:[index intValue]]) [self addCellAtIndex:[index intValue]];
		}		
	}
	else if (createRowDelta > 0) {
		// we've gained at least one row
		for (int i = createRowStart; i < createRowStart+createRowDelta; i++)
		{
			// add each row
			for (int j = 0; j < numCellsInRow;j++)
			{
				// create cell # i*[self numCellsInRow]+j --- check to make sure it actually exists!!! (e.g. incomplete row)
				// get view from datasource and add view in dictionary
				if (![self cellAtGridIndex:i*numCellsInRow+j]) [self addCellAtIndex:i*numCellsInRow+j];
			}
		}
	}
	self.currentScrollOffset = scrollView.contentOffset;
    
    // In OS 4.0 we should check if voice-over is active before sending this notification
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
//    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

-(void) setCellSize:(CGSize)size withBorderSize:(NSInteger) borderSize{
	currCellSize = size;
	minimumBorderSize = borderSize;
	currBorderSize = borderSize;
	[self calculateColumnCount]; 
}
-(void) setFrame:(CGRect)rect {
	[super setFrame:rect];
	[self calculateColumnCount]; 
	[self rearrangeCells];
}
-(void) calculateColumnCount {
	NSInteger totalWidth = self.frame.size.width;
	NSInteger widthMinusBorder = totalWidth - minimumBorderSize;
	NSInteger currentWidthPlusBorder = currCellSize.width + minimumBorderSize;
	NSInteger numberPerRow = floor((double)widthMinusBorder/(double)currentWidthPlusBorder);
	numCellsInRow = numberPerRow;
	currBorderSize = floor((totalWidth - numCellsInRow*currCellSize.width)/(numCellsInRow+1));
}

-(NSInteger) heightOfGrid {
	return currBorderSize+((currCellSize.height+currBorderSize)*[self rowCount]);
}

-(void) updateSize{
	int newHeight = [self heightOfGrid];
	CGRect newFrame = CGRectMake(gridView.frame.origin.x, gridView.frame.origin.x, gridView.frame.size.width, newHeight);
	self.contentSize = CGSizeMake(self.contentSize.width,newHeight);
	gridView.frame = newFrame;
}

-(CGRect) frameForCellAtGridIndex: (NSInteger) index{
	int rowNumber = floor((double)index/numCellsInRow);
	int positionInRow = index%numCellsInRow;
	
	float cellOriginX = (float)currBorderSize + ((currCellSize.width+currBorderSize)*positionInRow);
	float cellOriginY = (float)currBorderSize + ((currCellSize.height+currBorderSize)*rowNumber);
	
	return CGRectMake(cellOriginX,cellOriginY,currCellSize.width,currCellSize.height);
}

-(NSInteger)rowCount {
	return ceil((float)[gridDataSource numberOfItemsInGridView:self]/numCellsInRow);
}
-(void)activateCellDragging:(NSTimer *)aTimer {
//	NSLog(@"activateCellDragging");
//	NSLog(@"cellIndices count: %i, subviews count: %i",[cellIndices count],[[gridView subviews] count]);
	if (editTimer && [editTimer isValid]) [editTimer invalidate];
	editTimer = nil;
	cellDragging = YES;
	[self setScrollEnabled:NO];
	[gridView bringSubviewToFront:currDraggedCell];
	[self animateCellPickupForCell:currDraggedCell];
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesBegan:touches withEvent:event];
//	NSLog(@"touchesBegan, cellIndices count: %i, subviews count: %i",[cellIndices count],[[gridView subviews] count]);
	NSArray *touchArray = [touches allObjects];
//	NSLog(@"touchArray count: %i",[touchArray count]);
	if (_activeTouch == nil) {
		_activeTouch = [touchArray objectAtIndex:0];
		self.exclusiveTouch = YES;
		
	}
	if (_activeTouch == [touchArray objectAtIndex:0])
	{
		NSInteger touchedCellIndex = [self indexForTouchLocation:[_activeTouch locationInView:self]];
		if (self.isEditing && [gridDataSource gridView:self canMoveCellAtIndex:touchedCellIndex]){
		[self resetEditTimer];
		CGPoint touchLoc = [_activeTouch locationInView:self];
		self.currDraggedCell = (MRGridViewCell*)[self viewAtLocation:touchLoc];
//		NSLog(@"self.currDraggedCell: %@",self.currDraggedCell);
		currDraggedCellOriginalCenter = self.currDraggedCell.center;
		currDraggedCellIndex = touchedCellIndex;
		currentHoveredIndex = currDraggedCellIndex;
/*		
		//insert shadow cell
		CGRect shadowFrame = currDraggedCell.frame;
		shadowFrame.origin.x = shadowFrame.origin.x+shadowFrame.size.width*.1;
		shadowFrame.origin.y = shadowFrame.origin.y+shadowFrame.size.height*.1;
		shadowFrame.size.width = shadowFrame.size.width*.8;
		shadowFrame.size.height = shadowFrame.size.height*.8;
		shadowView = [[UIView alloc]initWithFrame:shadowFrame];
		shadowView.backgroundColor = [UIColor grayColor];
		
		//add views to grid and reposition accordingly
		[gridView addSubview:shadowView];
		[gridView sendSubviewToBack:shadowView];
 */
	}
	/*
    if (aTouch.tapCount == 2) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    }
	 */
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesMoved:touches withEvent:event];
	NSArray *touchArray = [touches allObjects];
//	NSLog(@"touchesMoved... touchArray count: %i",[touchArray count]);
//	NSLog(@"touchesMoved, cellIndices count: %i, subviews count: %i",[cellIndices count],[[gridView subviews] count]);
	UITouch *theTouch = nil;

	for (UITouch * touch in touchArray)
	{
		if (touch == _activeTouch) theTouch = touch;
	}
	if (theTouch == nil) return;
	
	if (self.isEditing && cellDragging){
//		NSArray *touchArray = [touches allObjects];
//		NSLog(@"touchArray count: %i",[touchArray count]);
		UITouch *theTouch = [touches anyObject];
		CGPoint touchLoc = [theTouch locationInView:self];
//		NSLog(@"currDraggedCell: %@",currDraggedCell);
		if (currDraggedCell){
			self.currDraggedCell.center = touchLoc;
			NSInteger previousHoveredIndex = currentHoveredIndex;
			if (self.moveStyle == MRGridViewMoveStyleMarker) [self putMarkerAtNearestSpace:touchLoc];
			else {
				CGPoint modifiedTouchLoc = touchLoc;
				if (modifiedTouchLoc.y <= self.contentOffset.y + 20) modifiedTouchLoc.y = self.contentOffset.y + 20;
				if (modifiedTouchLoc.y > self.contentOffset.y + self.bounds.size.height - 20) modifiedTouchLoc.y = self.contentOffset.y + self.bounds.size.height - 20;
				currentHoveredIndex = [self indexForTouchLocation:modifiedTouchLoc];
				// NSLog(@"currentHoveredIndex: %i",currentHoveredIndex);
				if (currentHoveredIndex >= [gridDataSource numberOfItemsInGridView:self]) currentHoveredIndex = [gridDataSource numberOfItemsInGridView:self] -1;
				if (previousHoveredIndex == -1) previousHoveredIndex = currDraggedCellIndex;
				if (previousHoveredIndex != currentHoveredIndex) {
					// dragged cell moved to a different slot
					[gridDataSource gridView:self moveCellAtIndex: previousHoveredIndex toIndex: currentHoveredIndex];

					// NSLog(@"previousHoveredIndex,currentHoveredIndex: %i,%i",previousHoveredIndex,currentHoveredIndex);
					NSInteger direction = -1;
					if (currentHoveredIndex > previousHoveredIndex) direction = 1;
					for (NSInteger i = previousHoveredIndex; i != currentHoveredIndex; i = i + direction)
					{
						// NSLog(@"i+direction to i: %i%i",i+direction,i);
						MRGridViewCell * cell = [cellIndices objectForKey:[NSNumber numberWithInt:i+direction]];
						if (cell) {
							[cellIndices setObject:cell forKey:[NSNumber numberWithInt:i]];
							[cellIndices removeObjectForKey:[NSNumber numberWithInt:i+direction]];
						}
						
					}
//					NSLog(@"currDraggedCell: %@",currDraggedCell);
					[cellIndices setObject:currDraggedCell forKey:[NSNumber numberWithInt:currentHoveredIndex]];
					[self rearrangeCells];
				}
			}
			lastTouchLocation = touchLoc;
			// calculate scroll intensity
			float topOfScreen = self.contentOffset.y;
			float bottomOfScreen = (self.contentOffset.y + self.frame.size.height);
			float zoneHeight = MRGridViewScrollOverlapHeight;
			if (lastTouchLocation.y >= (bottomOfScreen - zoneHeight))
			{
//				NSLog(@"lastTouchLocation.y,bottomOfScreen, zoneHeight: %f,%f,%f",lastTouchLocation.y,bottomOfScreen,zoneHeight);
				scrollIntensity = (lastTouchLocation.y - bottomOfScreen + zoneHeight)/zoneHeight;
				if (scrollIntensity > 1) scrollIntensity = 1;
				scrollIntensity = scrollIntensity * 1;
				[self resetScrollTimer];
			}
			else if (lastTouchLocation.y <= topOfScreen+zoneHeight)
			{
//				NSLog(@"lastTouchLocation.y,topOfScreen, zoneHeight: %f,%f,%f",lastTouchLocation.y,topOfScreen,zoneHeight);
				scrollIntensity = 1 - (lastTouchLocation.y-topOfScreen)/zoneHeight;
				if (scrollIntensity > 1) scrollIntensity = 1;
				scrollIntensity = scrollIntensity * -1;
				[self resetScrollTimer];
			}
			else 
			{
				// kill timer
				[self invalidateScrollTimer];
			}
		}
	}
	else if (self.isEditing) [self resetEditTimer];
}
	

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesEnded:touches withEvent:event];
//	NSLog(@"touchesEnded, cellIndices count: %i, subviews count: %i",[cellIndices count],[[gridView subviews] count]);
	NSArray *touchArray = [touches allObjects];
	// NSLog(@"touchArray count: %i",[touchArray count]);
	UITouch *theTouch = nil;
	
	for (UITouch * touch in touchArray)
	{
		if (touch == _activeTouch) theTouch = touch;
	}
	if (theTouch == nil) return;

	_activeTouch = nil;
	self.exclusiveTouch = NO;
	cellDragging = NO;
	[self setScrollEnabled:YES];
	[self invalidateEditTimer];
	[self invalidateScrollTimer];
    if (self.isEditing){
		//if there is a cell being dragged and it is being moved to another location
//		NSLog(@"currDraggedCell: %@", currDraggedCell);
		if (currDraggedCell){
			NSInteger maxIndex = [gridDataSource numberOfItemsInGridView:self];
			if (moveStyle == MRGridViewMoveStyleDisplace) {
				CGRect finalFrame = [self frameForCellAtGridIndex:currentHoveredIndex];
				CGPoint finalLocation = CGPointMake(finalFrame.origin.x + (finalFrame.size.width/2), finalFrame.origin.y + (finalFrame.size.height/2));
				[self animateCellPutdownForCell:currDraggedCell toLocation:finalLocation];
			}
			else {
				if (currDraggedCellIndex != currentHoveredIndex &&
					currDraggedCellIndex >= 0 && currDraggedCellIndex < maxIndex &&
					currentHoveredIndex >= 0 && currentHoveredIndex < maxIndex){
					//tell the datasource to update the position
					NSInteger fromIndex = currDraggedCellIndex;
					NSInteger toIndex = currentHoveredIndex;
					[self cleanupAfterCellDrop];
					[gridDataSource gridView:self moveCellAtIndex: fromIndex toIndex: toIndex];
					[self rearrangeCells];
				}
				else {
					[self animateCellPutdownForCell:currDraggedCell toLocation:currDraggedCellOriginalCenter];
				}
			}
		}
	}
	else if (theTouch.tapCount == 1) {
        CGPoint touchLoc = [theTouch locationInView:self];
		[self handleSingleTap: touchLoc];
    } 
	else {
		[self cleanupAfterCellDrop];
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesCancelled:touches withEvent:event];
//	NSLog(@"touchesCancelled");
	NSArray *touchArray = [touches allObjects];
	// NSLog(@"touchArray count: %i",[touchArray count]);
	UITouch *theTouch = nil;
	
	for (UITouch * touch in touchArray)
	{
		if (touch == _activeTouch) theTouch = touch;
	}
	if (theTouch == nil) return;

	self.exclusiveTouch = NO;
	_activeTouch = nil;
	cellDragging = NO;
	[self setScrollEnabled:YES];
	[self invalidateEditTimer];
	[self invalidateScrollTimer];
	[self cleanupAfterCellDrop];
}

-(void) resetScrollTimer {
	if (scrollTimer == nil) scrollTimer = [NSTimer scheduledTimerWithTimeInterval:0.02f target:self selector:@selector(scrollIfNeededAtPosition:) userInfo:nil repeats:YES];	
}

-(void) invalidateScrollTimer {
	if (scrollTimer) {
		// NSLog(@"scrollTimer being killed");
		if ([scrollTimer isValid]) [scrollTimer invalidate];
		scrollTimer = nil;
	}	
}
-(void) resetEditTimer {
	if (editTimer && [editTimer isValid]) [editTimer invalidate];
	editTimer = [NSTimer scheduledTimerWithTimeInterval:0.40f target:self selector:@selector(activateCellDragging:) userInfo:nil repeats:NO];	
}
-(void) invalidateEditTimer {
	if (editTimer) {
//		NSLog(@"editTimer being killed");
		if ([editTimer isValid]) [editTimer invalidate];
		editTimer = nil;
		[self cleanupAfterCellDrop];
	}	
}
-(void)scrollIfNeededAtPosition:(NSTimer*)aTimer {
	if (!currDraggedCell) {
		NSLog(@"currDraggedCell is not available. invalidating scroll timer...");
		[self invalidateScrollTimer];
		return;
	}
	
	if (self.contentSize.height < self.frame.size.height) {
		[self setContentOffset:CGPointMake(0, 0) animated:YES];
		[self invalidateScrollTimer];
		return;
	}
	float speed = MRGridViewDragScrollSpeed;

	float scrollTravel = ceil(scrollIntensity * speed);
	if ((self.contentOffset.y + scrollTravel) > self.contentSize.height - self.frame.size.height) scrollTravel = self.contentSize.height - self.frame.size.height - self.contentOffset.y;
	else if ((self.contentOffset.y + scrollTravel) < 0) scrollTravel = -self.contentOffset.y;
	self.contentOffset = CGPointMake(self.contentOffset.x,self.contentOffset.y + scrollTravel);
	currDraggedCell.center = CGPointMake(currDraggedCell.center.x,currDraggedCell.center.y+scrollTravel);
}

-(void)animateCellPickupForCell:(MRGridViewCell*)cell {
//	NSLog(@"animateCellPickupForCell");
//	NSLog(@"cellIndices count: %i, subviews count: %i",[cellIndices count],[[gridView subviews] count]);
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.15];
	cell.transform = CGAffineTransformMakeScale(1.2, 1.2);
	cellPrePickupAlpha = cell.alpha;
	cell.alpha = .8f;
	cell.center = [_activeTouch locationInView:self];
	[UIView commitAnimations];
	
}

-(void)animateCellPutdownForCell:(MRGridViewCell*)cell toLocation:(CGPoint)theLocation {
//	NSLog(@"animateCellPutdownForCell");
//	NSLog(@"cellIndices count: %i, subviews count: %i",[cellIndices count],[[gridView subviews] count]);
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.15];
	// Set the center to the final postion
	cell.center = theLocation;
	// Set the transform back to the identity, thus undoing the previous scaling effect.
	cell.transform = CGAffineTransformIdentity;
	cell.alpha = cellPrePickupAlpha;
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animateCellPutdownDidStop:finished:context:)];
	[UIView commitAnimations];
}
-(void)animateCellPutdownDidStop:(NSString *)animationID finished:(BOOL)finished context:(void *)context {
//	NSLog(@"animateCellPutdownDidStop");
//	NSLog(@"cellIndices count: %i, subviews count: %i",[cellIndices count],[[gridView subviews] count]);
	NSInteger indexOfCellToBeRemoved = currDraggedCellIndex;
	CGRect restingRect = [self frameForCellAtGridIndex:indexOfCellToBeRemoved];
	[gridDataSource gridView:self finishedMovingCellToIndex: currDraggedCellIndex];
	[self cleanupAfterCellDrop];
//	NSLog(@"restingRect: %f,%f,%f,%f",restingRect.origin.x,restingRect.origin.y,restingRect.size.width,restingRect.size.height);
//	NSLog(@"visible frame: %f,%f,%f,%f",self.contentOffset.x,self.contentOffset.y,self.frame.size.width,self.frame.size.height);

	if (moveStyle != MRGridViewMoveStyleDisplace && !CGRectIntersectsRect(restingRect, CGRectMake(self.contentOffset.x,self.contentOffset.y,self.frame.size.width,self.frame.size.height))) {
//		NSLog(@"cell doesn't intersect current visible frame");
		[self removeCellAtIndex:indexOfCellToBeRemoved];
	}
}
-(void)cleanupAfterCellDrop {
//	[shadowView removeFromSuperview];
//	[shadowView release];
//	shadowView = nil;
	_activeTouch = nil;
	currDraggedCell = nil;
	currDraggedCellIndex = -1;
	currentHoveredIndex = -1;
	markerView.hidden = YES;
}

- (void)handleSingleTap:(CGPoint)touchLoc {
    int index = [self indexForTouchLocation:touchLoc];
	[gridDelegate gridView:self didSelectCellAtIndex:index];
}

-(NSInteger) indexForTouchLocation:(CGPoint)touchLoc {
	float xPos = touchLoc.x;
	float yPos = touchLoc.y;
	int currWidth = currCellSize.width;
	int currHeight = currCellSize.height;
	
	int numInRow = numCellsInRow;
	int posInRow = floor((xPos-currBorderSize)/(currWidth+currBorderSize));
	if (numInRow == posInRow)
		posInRow = posInRow - 1;
	else if (posInRow < 0)
		posInRow = 0;
	
	int inRow = floor((yPos-currBorderSize)/(currHeight+currBorderSize));
	if (inRow < 0)
		inRow = 0;
	
	return posInRow + (inRow*numInRow);
}

-(NSArray*) indexesForCellsInRect:(CGRect)rect {
	NSMutableArray* cellIndexes = [NSMutableArray array];
	
	//figure out what index the origin is
	NSInteger firstIndex = [self indexForTouchLocation:rect.origin];
	
	
	//figure out how many rows the rect spans
	CGFloat startingY = rect.origin.y;
	NSInteger rowsAbove = floor((startingY-currBorderSize)/(currCellSize.height+currBorderSize));
	NSInteger rowsBelow = ceil((startingY-currBorderSize+rect.size.height)/(currCellSize.height+currBorderSize));
	
	NSInteger numRows = rowsBelow - rowsAbove;
	// add an extra row if we need to accommodate partial row at bottom
	//	CGFloat rowLeftover = (rect.origin.y-currBorderSize)/(currCellSize.height+currBorderSize);
	//	NSLog(@"rowLeftover: %f",rowLeftover);
	//	if (rowLeftover != floor(rowLeftover)) numRows++;
	
	//return indexes from start value to end value
	int totalCells = [gridDataSource numberOfItemsInGridView:self];
	for (NSInteger i = firstIndex;i<firstIndex+(numRows*numCellsInRow);i++){
		if (i >= 0 && i <= totalCells)
			[cellIndexes addObject:[NSNumber numberWithInt:i]];
	}
	return cellIndexes;
}

-(void) putMarkerAtNearestSpace:(CGPoint)touchLoc {
	NSInteger index = [self indexForTouchLocation:touchLoc];
	CGRect closestCellFrame = [self frameForCellAtGridIndex:index];
	float markerOriginX;
	float markerOriginY;
	//check to see if touch is farther to the right or left of cell position
	if (touchLoc.x > (closestCellFrame.origin.x + (closestCellFrame.size.width/2))){
		//if farther to right, make marker after cell
		markerOriginX = closestCellFrame.origin.x + closestCellFrame.size.width + (currBorderSize/4);
		markerOriginY = closestCellFrame.origin.y;
		currentHoveredIndex = index+1;
	}
	else {
		//if farther to left, make marker before cell
		markerOriginX = closestCellFrame.origin.x - (currBorderSize*.75f);
		markerOriginY = closestCellFrame.origin.y;
		currentHoveredIndex = index;
	}
	CGRect markerFrame = CGRectMake(markerOriginX, markerOriginY, currBorderSize/2, currCellSize.height);
	if (markerView==nil){
		markerView = [[UIView alloc]initWithFrame:markerFrame];
		markerView.backgroundColor = [UIColor blackColor];
		[gridView addSubview:markerView];
	}
	else markerView.frame = markerFrame;
	[gridView bringSubviewToFront:markerView];
}

-(UIView*) viewAtLocation:(CGPoint)touchLoc {
//	NSLog(@"MRGridView viewAtLocation: entered");
//	NSLog(@"cellIndices count: %i, subviews count: %i",[cellIndices count],[[gridView subviews] count]);
	UIView* currView;
	for (currView in gridView.subviews){
		if (CGRectContainsPoint([currView frame], touchLoc)) {
			return currView;
		}
	}
	return nil;
}

- (void)setEditing:(BOOL)editingVal animated:(BOOL)animate {
//	NSLog(@"MRGridView setEditing:%i animated:%i entered",editingVal,animate);
//	NSLog(@"cellIndices count: %i, subviews count: %i",[cellIndices count],[[gridView subviews] count]);
	self.editing = editingVal;
	NSInteger targetAlphaValue = 0;
	if (editingVal) targetAlphaValue = 1;
	if (animate) [UIView beginAnimations:@"editingStateChange" context:nil];
	NSArray * viewableCellIndexes = [self indexesForCellsInRect:[self bounds]];
	for (NSNumber * key in viewableCellIndexes) {
		MRGridViewCell * gridCell = [cellIndices objectForKey:key];
		gridCell.deleteButton.alpha = targetAlphaValue;
	}
	if (animate) [UIView commitAnimations];
}

-(void)deleteIndices:(NSArray*)indices withCellAnimation:(MRGridViewCellAnimation)cellAnimation {
//	NSLog(@"MRGridView deleteIndices:withCellAnimation entered");
//	NSLog(@"cellIndices count: %i, subviews count: %i",[cellIndices count],[[gridView subviews] count]);
	for (NSNumber * deletedKey in indices) {
		if ([cellIndices objectForKey:deletedKey]) [self removeCellAtIndex:[deletedKey intValue]];
	}
	NSMutableArray * keys = [NSMutableArray array];
	for (id key in cellIndices)
	{
		[keys addObject:key];
	}
	// sort keys
	NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"intValue" ascending:YES];
	[keys sortUsingDescriptors:[NSArray arrayWithObject:sorter]];
	for (NSInteger i = 0; i < [keys count]; i++) {
		NSNumber * key = [keys objectAtIndex:i];
		NSInteger adjustment = 0;
		for (NSNumber * deletedKey in indices) {
			if ([deletedKey intValue] < [key intValue]) adjustment++;
		}
		if (adjustment > 0) {
			NSInteger newKeyValue = [key intValue] - adjustment;
			MRGridViewCell * gridCell = [cellIndices objectForKey:key];
			[cellIndices removeObjectForKey:key];
			[cellIndices setObject:gridCell forKey:[NSNumber numberWithInt:newKeyValue]];
		}
	}
	[sorter release];
	[self rearrangeCells];
}
- (void)dealloc {
	self.gridDataSource = nil;
	self.gridDelegate = nil;
	self.reusableCells = nil;
	self.cellIndices = nil;
	[super dealloc];
}


@end
