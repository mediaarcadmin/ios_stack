//
//  EucCSSLayoutTableTable.h
//  libEucalyptus
//
//  Created by James Montgomerie on 21/12/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucCSSLayoutTableBox.h"

@class EucCSSIntermediateDocumentNode, EucCSSLayoutTableWrapper, EucCSSLayoutTableHeaderGroup, EucCSSLayoutTableFooterGroup;

@interface EucCSSLayoutTableTable : EucCSSLayoutTableBox {
    EucCSSLayoutTableHeaderGroup *_headerGroup;
    NSMutableArray *_rowGroups;
    EucCSSLayoutTableFooterGroup *_footerGroup;
    
    NSMutableArray *_columnGroups;
}

@property (nonatomic, retain) EucCSSLayoutTableHeaderGroup *headerGroup;
@property (nonatomic, retain) NSArray *rowGroups;
@property (nonatomic, retain) EucCSSLayoutTableFooterGroup *footerGroup;

@property (nonatomic, retain) NSArray *columnGroups;

- (id)initWithNode:(EucCSSIntermediateDocumentNode *)node wrapper:(EucCSSLayoutTableWrapper *)wrapper;

@end
