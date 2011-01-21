//
//  EucCSSLayoutSizedTable.m
//  libEucalyptus
//
//  Created by James Montgomerie on 04/01/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutSizedTable.h"
#import "EucCSSLayoutSizedTableCell.h"
#import "EucCSSLayoutSizedBlock.h"

#import "EucCSSLayoutTableWrapper.h"
#import "EucCSSLayoutTableCaption.h"
#import "EucCSSLayoutTableTable.h"
#import "EucCSSLayoutTableColumnGroup.h"
#import "EucCSSLayoutTableColumn.h"
#import "EucCSSLayoutTableRowGroup.h"
#import "EucCSSLayoutTableRow.h"
#import "EucCSSLayoutTableCell.h"

#import "EucCSSLayoutPositionedTable.h"
#import "EucCSSLayoutPositionedTableCell.h"

#import "EucCSSIntermediateDocumentNode.h"

#import "EucCSSInternal.h"

#import "THPair.h"
#import "THLog.h"

#import <libcss/libcss.h>

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
        _sizedCells = CFDictionaryCreateMutable(kCFAllocatorDefault,
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
                    EucCSSLayoutSizedTableCell *sizedCell = [cell sizedTableCellWithScaleFactor:scaleFactor];
                    CFDictionarySetValue(_sizedCells, cell, sizedCell);
                    
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
                NSUInteger columnSpan;
                if(cell) {
                    columnSpan = cell.columnSpan;
                    if(columnSpan == 1) {
                        EucCSSLayoutSizedEntity *sizedCellContents = (EucCSSLayoutSizedEntity *)CFDictionaryGetValue(_sizedCells, cell);
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
                } else {
                    columnSpan = 1;
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
                NSUInteger columnSpan;
                if(cell) {
                    columnSpan = cell.columnSpan;
                    if(columnSpan > 1) {
                        CGFloat spannedMin = 0, spannedMax = 0;
                        for(NSUInteger i = 0; i < columnSpan; ++i) {
                            spannedMin += _columnMinWidths[columnIndex + i];
                            spannedMax += _columnMaxWidths[columnIndex + i];
                        }
                        EucCSSLayoutSizedEntity *sizedCellContents = (EucCSSLayoutSizedEntity *)CFDictionaryGetValue(_sizedCells, cell);
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
                } else {
                    columnSpan = 1;
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
- (CGFloat)cellsMinWidth
{
    CGFloat ret = 0.0f;
    for(NSUInteger i = 0; i < _columnCount; ++i) {
        ret += _columnMinWidths[i];
    }    
    return ret;
}

- (CGFloat)minWidth
{
    CGFloat cellsMin = self.cellsMinWidth;
    
    EucCSSLayoutSizedBlock *sizedCaptionBlock = self.sizedCaptionBlock;
    CGFloat capMin;
    if(sizedCaptionBlock) {
        capMin = [sizedCaptionBlock minWidth];
    } else {
        capMin = 0.0f;
    }
    
    return MAX(cellsMin, capMin);
}

- (CGFloat)cellsMaxWidth
{
    CGFloat ret = 0.0f;
    for(NSUInteger i = 0; i < _columnCount; ++i) {
        ret += _columnMaxWidths[i];
    }    
    return ret;
}

- (CGFloat)maxWidth
{
    CGFloat cellsMax = self.cellsMaxWidth;
    
    EucCSSLayoutSizedBlock *sizedCaptionBlock = self.sizedCaptionBlock;
    CGFloat capMax;
    if(sizedCaptionBlock) {
        capMax = [sizedCaptionBlock maxWidth];
    } else {
        capMax = 0.0f;
    }
    
    return MAX(cellsMax, capMax);
}

- (EucCSSLayoutSizedBlock *)sizedCaptionBlock
{
    if(!_sizedCaptionBlock) {
        EucCSSLayoutTableCaption *caption = _tableWrapper.caption;
        if(caption) {
            _sizedCaptionBlock = [caption sizedContentsWithScaleFactor:_scaleFactor];
        }
    }
    return _sizedCaptionBlock;
}

- (CGFloat)widthInContainingBlockOfWidth:(CGFloat)width
{    
    CGFloat tableWidth = 0.0f;
        
    EucCSSLayoutTableTable *table = _tableWrapper.table;

    enum css_width_e widthKind;
    if(table.documentNodeIsRepresentative) {
        css_fixed tableWidthFixed = 0;
        css_unit tableWidthUnit = 0;
        css_computed_style *style = table.documentNode.computedStyle;
        widthKind = (enum css_width_e)css_computed_width(style, &tableWidthFixed, &tableWidthUnit);
        if(widthKind == CSS_WIDTH_SET) {
            tableWidth = EucCSSLibCSSSizeToPixels(style, tableWidthFixed, tableWidthUnit, width, _scaleFactor);
        } else {
            if(widthKind != CSS_WIDTH_AUTO) {
                THWarn(@"Unexpected width kind %ld for table", (long)widthKind);
            }
            widthKind = CSS_WIDTH_AUTO;
        }
    } else {
        widthKind = CSS_WIDTH_AUTO;
    }

    if(widthKind == CSS_WIDTH_AUTO) {
        CGFloat capMin = self.sizedCaptionBlock.minWidth;
        CGFloat cellMin = self.cellsMinWidth;
        tableWidth = MAX(capMin, cellMin);
        tableWidth = MAX(tableWidth, width);
        if(tableWidth > width) {
            tableWidth = width;  // Not the suggested algorithm, but looks better - tables don't overflow the page.
        }
    } else {
        // tableWidth currently holds the computed specified value.
        CGFloat capMin = self.sizedCaptionBlock.minWidth;
        CGFloat cellMin = self.cellsMinWidth;
        tableWidth = MAX(tableWidth, capMin);
        tableWidth = MAX(tableWidth, cellMin);
        tableWidth = MAX(tableWidth, width);
        if(tableWidth > width) {
            tableWidth = width;  // Not the suggested algorithm, but looks better - tables don't overflow the page.
        }
    }
    
    return tableWidth;
}


- (EucCSSLayoutPositionedTable *)positionTableForFrame:(CGRect)frame
                                           inContainer:(EucCSSLayoutPositionedContainer *)container
                                         usingLayouter:(EucCSSLayouter *)layouter
{
    return [self positionTableForFrame:frame inContainer:container usingLayouter:layouter fromRowOffset:0];
}

- (EucCSSLayoutPositionedTable *)positionTableForFrame:(CGRect)frame
                                           inContainer:(EucCSSLayoutPositionedContainer *)container
                                         usingLayouter:(EucCSSLayouter *)layouter
                                         fromRowOffset:(NSUInteger)rowOffset
{
    EucCSSLayoutPositionedTable *positionedTable = [[EucCSSLayoutPositionedTable alloc] initWithColumnCount:_columnCount
                                                                                                   rowCount:_rowCount];

    CGFloat width = [self widthInContainingBlockOfWidth:frame.size.width];
    
    positionedTable.frame = frame;
    
    CGFloat *columnWidths = calloc(_columnCount, sizeof(CGFloat));
    CGFloat cellsMinWidth = self.cellsMinWidth;
    
    CGFloat accumulatedColumnWidth = 0;
    for(NSUInteger i = 0; i < _columnCount; ++i) {
        CGFloat colWidth = (_columnMinWidths[i] / cellsMinWidth) * width;
        colWidth = MIN(colWidth, _columnMaxWidths[i]);
        colWidth = floorf(colWidth);
        columnWidths[i] = colWidth;
        accumulatedColumnWidth += colWidth;
    }
    
    if(_columnCount) {
        CGFloat notAccountedForWidth = width - accumulatedColumnWidth;
        BOOL allAtMax = NO;
        while(notAccountedForWidth > 0) {
            BOOL foundNonMax = NO;
            for(NSUInteger i = 0; notAccountedForWidth > 0 && i < _columnCount; ++i) {
                if(allAtMax || columnWidths[i] < _columnMaxWidths[i]) {
                    ++columnWidths[i];
                    --notAccountedForWidth;
                    foundNonMax = YES;
                }
            }
            allAtMax = !foundNonMax;
        }
    }
    
    NSMutableArray *currentRowSpanningCells = [[NSMutableArray alloc] init];
    CFMutableSetRef placedCells = CFSetCreateMutable(kCFAllocatorDefault,
                                                     _rowCount * _columnCount,
                                                     &kCFTypeSetCallBacks);
    CFMutableSetRef rowPositionedCells = CFSetCreateMutable(kCFAllocatorDefault,
                                                            _columnCount,
                                                            &kCFTypeSetCallBacks);
    
    CGRect cellFrame = positionedTable.contentRect;

    for(NSUInteger rowIndex = 0; rowIndex < _rowCount; ++rowIndex) {
        if(rowOffset == 0 || rowIndex >= rowOffset - 1) {
            // Place all the cells for this row.
            NSNumber *rowIndexNumber = [[NSNumber alloc] initWithUnsignedInteger:rowIndex];
            
            CGFloat rowHeight = 0.0f;
            for(NSUInteger columnIndex = 0; columnIndex < _columnCount;) {
                NSNumber *columnIndexNumber = [[NSNumber alloc] initWithUnsignedInteger:columnIndex];
                EucCSSLayoutTableCell *cell = [[_cellMap objectForKey:rowIndexNumber] objectForKey:columnIndexNumber];
                NSUInteger columnSpan;
                if(cell) {
                    columnSpan = cell.columnSpan;
                    if(!CFSetContainsValue(placedCells, cell)) {
                        EucCSSLayoutSizedTableCell *sizedCell = (EucCSSLayoutSizedTableCell *)CFDictionaryGetValue(_sizedCells, cell);
                               
                        cellFrame.size.width = columnWidths[columnIndex];
                        for(NSUInteger i = 1; i < columnSpan; ++i) {
                            cellFrame.size.width += columnWidths[columnIndex + i];
                        }
                        
                        EucCSSLayoutPositionedTableCell *positionedCell = [sizedCell positionCellForFrame:cellFrame
                                                                                                  inTable:positionedTable
                                                                                            atColumnIndex:columnIndex
                                                                                                 rowIndex:rowIndex
                                                                                            usingLayouter:layouter];
                        CGFloat cellHeight = positionedCell.frame.size.height;
                        if(cellHeight > rowHeight) {
                            rowHeight = cellHeight;
                        }
                        
                        NSUInteger rowSpan = cell.rowSpan;
                        if(rowSpan > 1) {
                            [currentRowSpanningCells addPairWithFirst:positionedCell 
                                                               second:[NSNumber numberWithUnsignedInteger:rowIndex + rowSpan - 1]];
                        }
                        
                        CFSetAddValue(placedCells, cell);
                        CFSetAddValue(rowPositionedCells, positionedCell);
                        cellFrame.origin.x += cellFrame.size.width;
                    } 
                } else {
                    columnSpan = 1;
                }
                columnIndex += columnSpan;
                
                [columnIndexNumber release];
            }
            
            // TODO: Align the tops.
            // for(EucCSSLayoutPositionedTableCell cell in 
            
            // Do we have any spanned cells ending in this row?
            for(THPair *columnAndEndRowIndex in currentRowSpanningCells) {
                NSUInteger endRowIndex = [columnAndEndRowIndex.second unsignedIntegerValue];
                if(endRowIndex == rowIndex) {
                    EucCSSLayoutPositionedTableCell *positionedCell = columnAndEndRowIndex.first;
                    // TODO: take into account vertical alignment = middle and bottom.
                    CGFloat needsExtra = (cellFrame.origin.y + rowHeight) - CGRectGetMaxY(positionedCell.frame);
                    if(needsExtra > 0) {
                        [positionedCell setExtraPaddingBottom:needsExtra]; 
                    } else {
                        rowHeight += needsExtra;
                    }
                }
            }        
            
            // Pad the heights to make equal.
            for(EucCSSLayoutPositionedTableCell *positionedCell in (NSSet *)rowPositionedCells) {
                // TODO: take into account vertical alignment = middle and bottom.
                CGFloat needsExtra = (cellFrame.origin.y + rowHeight) - CGRectGetMaxY(positionedCell.frame);
                [positionedCell setExtraPaddingBottom:needsExtra]; 
            }
            
            cellFrame.origin.x = frame.origin.x;
            cellFrame.origin.y += rowHeight;

            CFSetRemoveAllValues(rowPositionedCells);
            
            [rowIndexNumber release];
        }
    }
    
    [currentRowSpanningCells release];
    CFRelease(rowPositionedCells);
    CFRelease(placedCells);
    free(columnWidths);
    
    [positionedTable closeBottomWithContentHeight:cellFrame.origin.y];
    
    [container addChild:positionedTable];
    
    return [positionedTable autorelease];
}

- (void)dealloc
{
    if(_sizedCells) {
        CFRelease(_sizedCells);
    }
    free(_columnMinWidths);
    free(_columnMaxWidths);
    
    [_cellMap release];
    [_tableWrapper release];
    
    [super dealloc];
}

@end
