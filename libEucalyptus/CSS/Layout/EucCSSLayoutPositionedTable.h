//
//  EucCSSLayoutPositionedTable.h
//  libEucalyptus
//
//  Created by James Montgomerie on 04/01/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif

#import "EucCSSLayoutPositionedContainer.h"

@class EucCSSLayoutPositionedTableCell;

@interface EucCSSLayoutPositionedTable : EucCSSLayoutPositionedContainer {
    NSUInteger _columnCount;
    NSUInteger _rowCount;
    
    NSUInteger _truncatedRowCount;
    
    EucCSSLayoutPositionedTableCell ***_cells;
}

@property (nonatomic, assign, readonly) NSUInteger rowCount;
@property (nonatomic, assign, readonly) NSUInteger columnCount;

- (id)initWithColumnCount:(NSUInteger)columnCount rowCount:(NSUInteger)rowCount;

- (void)setPositionedCell:(EucCSSLayoutPositionedTableCell *)cell forColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;
- (EucCSSLayoutPositionedTableCell *)positionedCellForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;

- (void)truncateFromRowContainingPositionedCell:(EucCSSLayoutPositionedTableCell *)positionedCell;

@end
