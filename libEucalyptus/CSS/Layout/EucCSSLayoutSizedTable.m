//
//  EucCSSLayoutSizedTable.m
//  libEucalyptus
//
//  Created by James Montgomerie on 04/01/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutSizedTable.h"

#import "EucCSSLayoutTableWrapper.h"
#import "EucCSSLayoutTableTable.h"
#import "EucCSSLayoutTableColumnGroup.h"
#import "EucCSSLayoutTableColumn.h"
#import "EucCSSLayoutTableRowGroup.h"
#import "EucCSSLayoutTableRow.h"
#import "EucCSSLayoutTableCell.h"

#import "THLog.h"

@implementation EucCSSLayoutSizedTable


- (NSMutableDictionary *)_cellsForRow:(NSUInteger)row
{
    NSNumber *key = [[NSNumber alloc] initWithUnsignedInteger:row];
    NSMutableDictionary *ret = [_cellMap objectForKey:key];
    if(!ret) {
        ret = [[NSMutableDictionary alloc] init];
        [_cellMap setObject:ret forKey:key];
        [ret release];
    }
    [key release];
    return ret;
}

- (id)initWithTableWrapper:(EucCSSLayoutTableWrapper *)tableWrapper
               scaleFactor:(CGFloat)scaleFactor
{
    if((self = [super initWithScaleFactor:scaleFactor])) {
        _tableWrapper = [tableWrapper retain];
        
        _cellMap = [[NSMutableDictionary alloc] init];
        _sizedContainers = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                                     0,
                                                     &kCFTypeDictionaryKeyCallBacks,
                                                     &kCFTypeDictionaryValueCallBacks);
        
        NSUInteger columnCount = 0;
        NSUInteger rowCount = 0;
        for(EucCSSLayoutTableRowGroup *rowGroup in _tableWrapper.table.rowGroups) {
            for(EucCSSLayoutTableRow *row in rowGroup.rows) {
                NSUInteger cellCount = 0;
                NSMutableDictionary *rowCells = [self _cellsForRow:rowCount];
                for(EucCSSLayoutTableCell *cell in row.cells) {
                    EucCSSLayoutSizedContainer *sizedCellContents = [cell sizedContentsWithScaleFactor:scaleFactor];
                    CFDictionarySetValue(_sizedContainers, cell, sizedCellContents);
                    
                    NSUInteger columnSpan = cell.columnSpan;
                    NSUInteger rowSpan = cell.rowSpan;
                    BOOL blocked;
                    do {
                        // Work out if our placement is blocked by row-spanning
                        // cells from previous rows, move it to the right
                        // if so.
                        blocked = NO;
                        NSUInteger cellPlace = cellCount;
                        for(; cellPlace < cellCount + columnSpan; ++cellPlace) {
                            if([rowCells objectForKey:[NSNumber numberWithUnsignedInteger:cellPlace]]) {
                                cellCount = cellPlace + 1;
                                blocked = YES;
                                break;
                            }
                        }
                    } while(blocked);
                    
                    for(NSUInteger cellPlace = cellCount; cellPlace < cellCount + columnSpan; ++cellPlace) {
                        [rowCells setObject:cell forKey:[NSNumber numberWithUnsignedInteger:cellPlace]];
                        for(NSUInteger rowPlace = rowCount + 1; rowPlace < rowCount + rowSpan; ++cellPlace) {
                            NSMutableDictionary *spanningRowCells = [self _cellsForRow:rowPlace];
                            [spanningRowCells setObject:cell forKey:[NSNumber numberWithUnsignedInteger:cellPlace]];
                        }
                    }
                    cellCount += columnSpan;
                }
                if(cellCount > columnCount) {
                    columnCount = cellCount;
                }
                ++rowCount;
            }
        }
        
        NSUInteger specifiedColumnCount = 0;
        for(EucCSSLayoutTableColumnGroup *columnGroup in _tableWrapper.table.columnGroups) {
            specifiedColumnCount += columnGroup.columns.count;
        }
        if(specifiedColumnCount > columnCount) {
            columnCount = specifiedColumnCount;
        }
        
        _columnCount = columnCount;
        _rowCount = rowCount;
        
        THLog(@"Table with [%ld, %ld] cells", (long)columnCount, (long)rowCount);

        /*
         From http://www.w3.org/TR/CSS2/tables.html:
         
         Column widths are determined as follows:
         
         1. Calculate the minimum content width (MCW) of each cell: the
            formatted content may span any number of lines but may not overflow
            the cell box. If the specified 'width' (W) of the cell is greater
            than MCW, W is the minimum cell width. A value of 'auto' means that
            MCW is the minimum cell width.
         
         2. Also, calculate the "maximum" cell width of each cell: formatting 
            the content without breaking lines other than where explicit line
            breaks occur.
         
         3. For each column, determine a maximum and minimum column width from
            the cells that span only that column. The minimum is that required
            by the cell with the largest minimum cell width (or the column
            'width', whichever is larger). The maximum is that required by the
            cell with the largest maximum cell width (or the column 'width',
            whichever is larger).
         
         4. For each cell that spans more than one column, increase the minimum
            widths of the columns it spans so that together, they are at least
            as wide as the cell. Do the same for the maximum widths. If
            possible, widen all spanned columns by approximately the same
            amount.
         
         5. For each column group element with a 'width' other than 'auto',
            increase the minimum widths of the columns it spans, so that
            together they are at least as wide as the column group's 'width'.
         
         This gives a maximum and minimum width for each column.
        */

        _columnMinWidths = calloc(columnCount, sizeof(CGFloat));
        _columnMaxWidths = calloc(columnCount, sizeof(CGFloat));

        // First, get the column widths if any (sort of step 1, above)
        {
            NSUInteger columnIndex = 0;
            for(EucCSSLayoutTableColumnGroup *columnGroup in tableWrapper.table.columnGroups) {
                for(EucCSSLayoutTableColumn *column in columnGroup.columns) {
                    CGFloat minWidth = [column widthWithScaleFactor:scaleFactor];
                    if(minWidth != CGFLOAT_MAX) {
                        _columnMinWidths[columnIndex] = minWidth; 
                    }
                    ++columnIndex;
                }
            }
        }
        
        // Step 3, above:
        for(NSUInteger rowIndex = 0; rowIndex < rowCount; ++rowIndex) {
            NSNumber *rowNumber = [[NSNumber alloc] initWithUnsignedInteger:rowIndex];
            
            for(NSUInteger columnIndex = 0; columnIndex < columnCount;) {
                NSNumber *columnNumber = [[NSNumber alloc] initWithUnsignedInteger:columnIndex];
                
                EucCSSLayoutTableCell *cell = [[_cellMap objectForKey:rowNumber] objectForKey:columnNumber];
                NSUInteger columnSpan = cell.columnSpan;
                if(columnSpan == 1) {
                    EucCSSLayoutSizedContainer *sizedCellContents = (EucCSSLayoutSizedContainer *)CFDictionaryGetValue(_sizedContainers, cell);
                    CGFloat minWidth = sizedCellContents.minWidth;
                    if(minWidth > _columnMinWidths[columnIndex]) {
                        _columnMinWidths[columnIndex] = minWidth;
                    } else {
                        minWidth = _columnMinWidths[columnIndex];
                    }
                    CGFloat maxWidth = sizedCellContents.maxWidth;
                    maxWidth = MAX(maxWidth, minWidth);
                    if(maxWidth > _columnMaxWidths[columnIndex]) {
                        _columnMaxWidths[columnIndex] = maxWidth;
                    }
                }
                
                [columnNumber release];
                columnIndex += columnSpan;
            }
            [rowNumber release];
        }
        
        // Step 4, above:
        for(NSUInteger row = 0; row < rowCount; ++row) {
            NSNumber *rowNumber = [[NSNumber alloc] initWithUnsignedInteger:row];
            
            for(NSUInteger columnIndex = 0; columnIndex < columnCount;) {
                NSNumber *columnNumber = [[NSNumber alloc] initWithUnsignedInteger:columnIndex];
                
                EucCSSLayoutTableCell *cell = [[_cellMap objectForKey:rowNumber] objectForKey:columnNumber];
                NSUInteger columnSpan = cell.columnSpan;
                if(columnSpan > 1) {
                    CGFloat spannedMin = 0, spannedMax = 0;
                    for(NSUInteger i = 0; i < columnSpan; ++i) {
                        spannedMin += _columnMinWidths[columnIndex + i];
                        spannedMax += _columnMaxWidths[columnIndex + i];
                    }
                    EucCSSLayoutSizedContainer *sizedCellContents = (EucCSSLayoutSizedContainer *)CFDictionaryGetValue(_sizedContainers, cell);
                    CGFloat minWidth = sizedCellContents.minWidth;
                    {
                        CGFloat remainingMinSpannedWidth = minWidth - spannedMin;
                        if(remainingMinSpannedWidth > 0) {
                            NSUInteger remainingColumnsToSpan = columnSpan;
                            for(NSUInteger i = 0; i < columnSpan; ++i) {
                                CGFloat addition = roundf(remainingMinSpannedWidth / remainingColumnsToSpan);
                                _columnMinWidths[columnIndex + i] += addition;
                                remainingMinSpannedWidth -= addition;
                                --remainingColumnsToSpan;
                            }                        
                        }
                    }
                    {
                        CGFloat maxWidth = sizedCellContents.maxWidth;
                        maxWidth = MAX(minWidth, maxWidth);
                        CGFloat remainingMaxSpannedWidth = maxWidth - spannedMax;
                        if(remainingMaxSpannedWidth > 0) {
                            NSUInteger remainingColumnsToSpan = columnSpan;
                            for(NSUInteger i = 0; i < columnSpan; ++i) {
                                CGFloat addition = roundf(remainingMaxSpannedWidth / remainingColumnsToSpan);
                                _columnMaxWidths[columnIndex + i] += addition;
                                remainingMaxSpannedWidth -= addition;
                                --remainingColumnsToSpan;
                            }                        
                        }
                    }
                }
                
                [columnNumber release];
                columnIndex += columnSpan;
            }
            [rowNumber release];
        }
        
        // Step 5, above:
        {
            NSUInteger columnIndex = 0;
            for(EucCSSLayoutTableColumnGroup *columnGroup in tableWrapper.table.columnGroups) {
                NSUInteger columnSpan = columnGroup.columns.count;
                CGFloat minWidth = [columnGroup widthWithScaleFactor:scaleFactor];
                if(minWidth != CGFLOAT_MAX) {
                    CGFloat spannedMin = 0;
                    for(NSUInteger i = 0; i < columnSpan; ++i) {
                        spannedMin += _columnMinWidths[columnIndex + i];
                    }
                    CGFloat remainingMinSpannedWidth = minWidth - spannedMin;
                    if(remainingMinSpannedWidth > 0) {
                        NSUInteger remainingColumnsToSpan = columnSpan;
                        for(NSUInteger i = 0; i < columnSpan; ++i) {
                            CGFloat addition = roundf(remainingMinSpannedWidth / remainingColumnsToSpan);
                            _columnMinWidths[columnIndex + i] += addition;
                            remainingMinSpannedWidth -= addition;
                        }                        
                    }
                }
                columnIndex += columnSpan;
            }
        }
    }
    return self;
}

// TODO: take into account margins etc.
- (CGFloat)minWidth
{
    CGFloat ret = 0.0f;
    for(NSUInteger i = 0; i < _columnCount; ++i) {
        ret += _columnMinWidths[i];
    }    
    return ret;
}

- (CGFloat)maxWidth
{
    CGFloat ret = 0.0f;
    for(NSUInteger i = 0; i < _columnCount; ++i) {
        ret += _columnMaxWidths[i];
    }    
    return ret;
}

- (void)dealloc
{
    if(_sizedContainers) {
        CFRelease(_sizedContainers);
    }
    free(_columnMinWidths);
    free(_columnMaxWidths);
    
    /*for(NSUInteger i = 0; i < _rowCount; ++i) {
        for(NSUInteger j = 0; j < _columnCount; ++j) {
            [_cellContainers[i][j] release];
        }
        free(_cellContainers[i]);
    }
    free(_cellContainers);*/
    
    [_cellMap release];
    [_tableWrapper release];
    
    [super dealloc];
}

@end
