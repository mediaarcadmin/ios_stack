//
//  EucCSSLayoutPositionedTable.m
//  libEucalyptus
//
//  Created by James Montgomerie on 04/01/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutPositionedTable.h"

#import "EucCSSLayoutPositionedTableCell.h"

@implementation EucCSSLayoutPositionedTable

@synthesize rowCount = _rowCount;
@synthesize columnCount = _columnCount;

- (id)initWithColumnCount:(NSUInteger)columnCount rowCount:(NSUInteger)rowCount
{
    if((self = [super init])) {
        _columnCount = columnCount;
        _rowCount = rowCount;
        
        _cells = malloc(sizeof(EucCSSLayoutPositionedTableCell **) * columnCount);
        for(NSUInteger i = 0; i < columnCount; ++i) {
            _cells[i] = calloc(rowCount, sizeof(EucCSSLayoutPositionedTableCell *));
        }
    }
    return self;
}

- (void)setPositionedCell:(EucCSSLayoutPositionedTableCell *)cell forColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex
{
    if(_cells[columnIndex][rowIndex] != cell) {
        [_cells[columnIndex][rowIndex] release];
        _cells[columnIndex][rowIndex] = [cell retain];
    }
    cell.parent = self;
}

- (EucCSSLayoutPositionedTableCell *)positionedCellForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex
{
    return _cells[columnIndex][rowIndex];
}

- (void)truncateFromRowContainingPositionedCell:(EucCSSLayoutPositionedTableCell *)positionedCell
{
    for(NSUInteger i = 0; i < _columnCount; ++i) {
        for(NSUInteger j = 0; j < _rowCount; ++j) {
            if(_cells[i][j] == positionedCell) {
                _truncatedRowCount = _rowCount - j;
                goto breakBothLoops;
            }
        }
    }
breakBothLoops:
    ;
}

- (NSUInteger)rowCount
{
    return _rowCount - _truncatedRowCount;
}

- (void)dealloc
{
    for(NSUInteger i = 0; i < _columnCount; ++i) {
        for(NSUInteger j = 0; j < _rowCount; ++j) {
            [_cells[i][j] release];
        }
        free(_cells[i]);
    }
    free(_cells);
    
    [super dealloc];
}

@end
