//
//  MRGridView.m
//  scifi
//
//  Created by Sean Doherty on 3/20/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import "MRGridView.h"

@interface MRGridView (PRIVATE)
- (void)invalidateScrollTimer;
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
		
	}
    return self;
}
- (void) addCellAtIndex:(NSInteger)cellIndex {
	if (cellIndex >=0 && cellIndex < [gridDataSource numberOfItemsInGridView:self] && cellIndex != currDraggedCellIndex)
	{
		MRGridViewCell * gridCell = [gridDataSource gridView:self cellForGridIndex:cellIndex];
		[cellIndices setObject:gridCell forKey:[NSNumber numberWithInt:cellIndex]];
		[gridView addSubview:gridCell];
		[gridView sendSubviewToBack:gridCell]; // we do this so that the cell will by default be "behind" a dragged cell.
	}
}
- (void) removeCellAtIndex:(NSInteger)cellIndex {
	MRGridViewCell * cell = nil;
	if (cellIndex >=0 && cellIndex < [gridDataSource numberOfItemsInGridView:self]  && cellIndex != currDraggedCellIndex) cell = [cellIndices objectForKey:[NSNumber numberWithInt:cellIndex]];
	if (cell != nil) {
		[cell removeFromSuperview];
		[self enqueueReusableCell:cell withIdentifier:cell.reuseIdentifier];
		[cellIndices removeObjectForKey:[NSNumber numberWithInt:cellIndex]];
	}	
}

//reloads data from dataSource
- (void)reloadData{
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
	NSLog(@"self bounds: %f,%f,%f,%f",[self bounds].origin.x,[self bounds].origin.y,[self bounds].size.width,[self bounds].size.height);
	NSArray * cellIndexes = [self indexesForCellsInRect:[self bounds]];
	for (NSNumber* index in cellIndexes){
		NSLog(@"new cellIndexes: %i",[index intValue]);
		[self addCellAtIndex:[index intValue]];
	}
	[self updateSize];
}

- (void)enqueueReusableCell: (MRGridViewCell*) cell withIdentifier:(NSString *)identifier{
	if (identifier != nil) {
		NSMutableArray* reusableCellsForIdentifier = (NSMutableArray*)[reusableCells objectForKey:identifier];
		if (reusableCellsForIdentifier == nil)
			reusableCellsForIdentifier = [NSMutableArray array];
		[reusableCellsForIdentifier addObject:cell];
		[reusableCells setObject:reusableCellsForIdentifier forKey:identifier];
	}
}

- (MRGridViewCell*)dequeueReusableCellWithIdentifier:(NSString *)identifier{
	MRGridViewCell* gridCell = nil;
	NSMutableArray* reusableCellsForIdentifier = (NSMutableArray*)[reusableCells objectForKey:identifier];
	if (reusableCellsForIdentifier && [reusableCellsForIdentifier count] > 0){
		gridCell = [[reusableCellsForIdentifier objectAtIndex:0] retain];
		if (gridCell){
			[reusableCellsForIdentifier removeObjectAtIndex:0];
			[gridCell prepareForReuse];
			[gridCell autorelease];
		}
	}
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
	
	if (recycleRowDelta >= self.bounds.size.height/currCellSize.height) {
		// total refresh - recycle all cells
		NSArray * cellIndexes = [self indexesForCellsInRect:CGRectMake(0, 0+scrollView.contentOffset.y, self.bounds.size.width, self.bounds.size.height)];
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
	if (createRowDelta >= self.bounds.size.height/currCellSize.height) {
		// total refresh - create all cells
		NSArray * cellIndexes = [self indexesForCellsInRect:[self bounds]];
		for (NSNumber* index in cellIndexes){
			[self addCellAtIndex:[index intValue]];
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
				[self addCellAtIndex:i*numCellsInRow+j];
			}
		}
	}
	self.currentScrollOffset = scrollView.contentOffset;
}

-(void) setCellSize:(CGSize)size withBorderSize:(NSInteger) borderSize{
	currCellSize = size;
	currBorderSize = borderSize;
	[self calculateColumnCount]; 
}
-(void) setFrame:(CGRect)rect {
	[super setFrame:rect];
	[self calculateColumnCount]; 
	[self reloadData];
}
-(void) calculateColumnCount {
	NSInteger totalWidth = gridView.frame.size.width;
	NSInteger widthMinusBorder = totalWidth - currBorderSize;
	NSInteger currentWidthPlusBorder = currCellSize.width + currBorderSize;
	NSInteger numberPerRow = floor((double)widthMinusBorder/(double)currentWidthPlusBorder);
	numCellsInRow = numberPerRow;
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

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *aTouch = [touches anyObject];
	if (self.isEditing){
		CGPoint touchLoc = [aTouch locationInView:self];
		self.currDraggedCell = (MRGridViewCell*)[self viewAtLocation:touchLoc];
		currDraggedCellOriginalCenter = self.currDraggedCell.center;
		currDraggedCellIndex = [self indexForTouchLocation:touchLoc];
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
		[gridView bringSubviewToFront:self.currDraggedCell];
		[self animateCellPickupForCell:currDraggedCell];
	}
	
    if (aTouch.tapCount == 2) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesMoved:touches withEvent:event];
	if (self.isEditing){
		UITouch *theTouch = [touches anyObject];
		CGPoint touchLoc = [theTouch locationInView:self];
		if (currDraggedCell){
			self.currDraggedCell.center = touchLoc;
			if (self.moveStyle == MRGridViewMoveStyleMarker) [self putMarkerAtNearestSpace:touchLoc];
			else currentHoveredIndex = [self indexForTouchLocation:touchLoc];
//			NSLog(@"currentHoveredIndex: %i",currentHoveredIndex);
			lastTouchLocation = touchLoc;
			[self scrollIfNeededAtPosition];
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	NSLog(@"touchesEnded");
	if (scrollTimer) [self invalidateScrollTimer];
    [super touchesEnded:touches withEvent:event];
	UITouch *theTouch = [touches anyObject];
    if (self.isEditing){
		//if there is a cell being dragged and it is being moved to another location
		if (currDraggedCell){
			NSInteger maxIndex = [gridDataSource numberOfItemsInGridView:self];
			if (currDraggedCellIndex != currentHoveredIndex &&
				currDraggedCellIndex >= 0 && currDraggedCellIndex < maxIndex &&
				currentHoveredIndex >= 0 && currentHoveredIndex < maxIndex){
//				if (moveStyle == MRGridViewMoveStyleDisplace) [self animateCellPutdownForCell:currDraggedCell toLocation:currentHoveredIndex];
				//tell the datasource to update the position
				NSInteger fromIndex = currDraggedCellIndex;
				NSInteger toIndex = currentHoveredIndex;
				[self cleanupAfterCellDrop];
				[gridDataSource gridView:self moveCellAtIndex: fromIndex toIndex: toIndex];
			}
			else {
				[self animateCellPutdownForCell:currDraggedCell toLocation:currDraggedCellOriginalCenter];
			}
		}
	}
	if (theTouch.tapCount == 1) {
        CGPoint touchLoc = [theTouch locationInView:self];
		[self handleSingleTap: touchLoc];
    } 
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	NSLog(@"touchesCancelled");
	if (scrollTimer) [self invalidateScrollTimer];
	[super touchesCancelled:touches withEvent:event];
	if (self.isEditing)
		[self cleanupAfterCellDrop];
}
-(void) invalidateScrollTimer {
	if (scrollTimer) {
		NSLog(@"scrollTimer being killed");
		[scrollTimer invalidate];
		scrollTimer = nil;
	}	
}
-(void)scrollIfNeededAtPosition {
	if (!currDraggedCell) {
		if (scrollTimer) [self invalidateScrollTimer];
		return;
	}
	CGPoint touchLocation = lastTouchLocation;
//	NSLog(@"lastTouchLocation.x,y: %f,%f",lastTouchLocation.x,lastTouchLocation.y);
	float topOfScreen = self.contentOffset.y;
	float bottomOfScreen = (self.contentOffset.y + self.frame.size.height);
	float zoneHeight = 44;
	float speed = 10;
	float intensity = 0;
	NSInteger direction = 0;
	if (touchLocation.y <= bottomOfScreen && touchLocation.y >= (bottomOfScreen - zoneHeight))
	{
		intensity = (touchLocation.y - bottomOfScreen + zoneHeight)/zoneHeight;
		direction = 1;
	}
	else if (touchLocation.y >= topOfScreen && touchLocation.y <= topOfScreen+zoneHeight)
	{
		intensity = 1 - (touchLocation.y-topOfScreen)/zoneHeight;
		direction = -1;
	}
	else 
	{
		// kill timer
		if (scrollTimer) [self invalidateScrollTimer];
		return;
	}
	float scrollTravel = ceil(intensity * speed * direction);
	if ((self.contentOffset.y + scrollTravel) > self.contentSize.height - self.frame.size.height) scrollTravel = self.contentSize.height - self.frame.size.height - self.contentOffset.y;
	else if ((self.contentOffset.y + scrollTravel) < 0) scrollTravel = -self.contentOffset.y;
//	NSLog(@"scrollTravel: %f",scrollTravel);
//	NSLog(@"scroll contentOffset before: %f,%f",self.contentOffset.x,self.contentOffset.y);
	self.contentOffset = CGPointMake(self.contentOffset.x,self.contentOffset.y + scrollTravel);
//	NSLog(@"scroll contentOffset after: %f,%f",self.contentOffset.x,self.contentOffset.y);
	currDraggedCell.center = CGPointMake(currDraggedCell.center.x,currDraggedCell.center.y+scrollTravel);
	if (scrollTimer == nil) scrollTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(scrollIfNeededAtPosition) userInfo:nil repeats:YES];
	/*
	//determine content offset based on variables
	if (touchLocation.y <= self.contentSize.height && 
		touchLocation.y > bottomOfScreen - currCellSize.height){
		if ((self.contentOffset.y+currCellSize.height) <= self.contentSize.height)
			[self setContentOffset:CGPointMake(self.contentOffset.x,(self.contentOffset.y+currCellSize.height)) animated:YES];
		else [self setContentOffset:CGPointMake(self.contentOffset.x,self.contentSize.height) animated:YES];
	} else if (touchLocation.y >= 0.0f && 
			   touchLocation.y < topOfScreen + currCellSize.height){
		if ((self.contentOffset.y-currCellSize.height) >=0.0f)
			[self setContentOffset:CGPointMake(self.contentOffset.x,(self.contentOffset.y-currCellSize.height)) animated:YES];
		else [self setContentOffset:CGPointMake(self.contentOffset.x,0.0f) animated:YES];
	}
	*/
}

-(void)animateCellPickupForCell:(MRGridViewCell*)cell {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.15];
//	cell.transform = CGAffineTransformMakeScale(1.2, 1.2);
	cell.alpha = .8f;
	[UIView commitAnimations];
}

-(void)animateCellPutdownForCell:(MRGridViewCell*)cell toLocation:(CGPoint)theLocation {
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.15];
	// Set the center to the final postion
	cell.center = theLocation;
	// Set the transform back to the identity, thus undoing the previous scaling effect.
//	cell.transform = CGAffineTransformIdentity;
	cell.alpha = 1.0f;
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animateCellPutdownDidStop:finished:context:)];
	[UIView commitAnimations];
}
-(void)animateCellPutdownDidStop:(NSString *)animationID finished:(BOOL)finished context:(void *)context {
	NSLog(@"animateCellPutdownDidStop");
	NSInteger indexOfCellToBeRemoved = currDraggedCellIndex;
	CGRect restingRect = [self frameForCellAtGridIndex:indexOfCellToBeRemoved];
	[self cleanupAfterCellDrop];
	NSLog(@"restingRect: %f,%f,%f,%f",restingRect.origin.x,restingRect.origin.y,restingRect.size.width,restingRect.size.height);
	NSLog(@"visible frame: %f,%f,%f,%f",self.contentOffset.x,self.contentOffset.y,self.frame.size.width,self.frame.size.height);
	if (!CGRectIntersectsRect(restingRect, CGRectMake(self.contentOffset.x,self.contentOffset.y,self.frame.size.width,self.frame.size.height))) {
		NSLog(@"cell doesn't intersect current visible frame");
		[self removeCellAtIndex:indexOfCellToBeRemoved];
	}
}
-(void)cleanupAfterCellDrop {
//	[shadowView removeFromSuperview];
//	[shadowView release];
//	shadowView = nil;
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
	UIView* currView;
	for (currView in gridView.subviews){
		if (CGRectContainsPoint([currView frame], touchLoc))
			return currView;
	}
	return nil;
}

- (void)setEditing:(BOOL)editingVal animated:(BOOL)animate {
	self.editing = editingVal;
	if (self.isEditing) {
		[self setScrollEnabled:NO];
	} else {
		[self setScrollEnabled:YES];
	}
}

- (void)dealloc {
	self.gridDataSource = nil;
	self.gridDelegate = nil;
	self.reusableCells = nil;
	self.cellIndices = nil;
	[super dealloc];
}


@end
