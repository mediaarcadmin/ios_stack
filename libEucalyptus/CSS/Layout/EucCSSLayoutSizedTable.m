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
                    EucCSSLayoutSizedContainer *sizedCellContents = [cell sizedContentsWithScaleFactor:_scaleFactor];
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
        CGFloat max = CGFLOAT_MAX;
        if(sizeof(CGFloat) == 4) {
            memset_pattern4(_columnMaxWidths, &max, columnCount * sizeof(CGFloat))
        } else {
            NSParameterAssert(CGFLOAT_IS_DOUBLE);
            memset_pattern8(_columnMaxWidths, &max, columnCount * sizeof(CGFloat))
        }
    }
    return self;
}

// TODO: non-fixed layout.
// TODO: take into account margins etc.

- (CGFloat)minWidth
{
    CGFloat ret = 0.0f;
    NSMutableDictionary *firstRow = [self _cellsForRow:0];
    for(NSUInteger i = 0; i < _columnCount;) {
        EucCSSLayoutTableCell *cell = [firstRow objectForKey:[NSNumber numberWithUnsignedInteger:i]];
        EucCSSLayoutSizedContainer *container = (EucCSSLayoutSizedContainer *)CFDictionaryGetValue(_sizedContainers, cell);
        
        NSParameterAssert(container);

        ret += container.minWidth;
        i += cell.columnSpan;
    }    
    return ret;
}

- (CGFloat)maxWidth
{
    CGFloat ret = 0.0f;
    NSMutableDictionary *firstRow = [self _cellsForRow:0];
    for(NSUInteger i = 0; i < _columnCount;) {
        EucCSSLayoutTableCell *cell = [firstRow objectForKey:[NSNumber numberWithUnsignedInteger:i]];
        EucCSSLayoutSizedContainer *container = (EucCSSLayoutSizedContainer *)CFDictionaryGetValue(_sizedContainers, cell);
        
        NSParameterAssert(container);
        
        CGFloat cellMaxWidth = container.maxWidth;
        if(cellMaxWidth != CGFLOAT_MAX) {
            ret += cellMaxWidth;
            i += cell.columnSpan;
        } else {
            ret = CGFLOAT_MAX;
            break;
        }
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
