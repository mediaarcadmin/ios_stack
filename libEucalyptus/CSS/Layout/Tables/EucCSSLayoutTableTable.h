//
//  EucCSSLayoutTableTable.h
//  libEucalyptus
//
//  Created by James Montgomerie on 21/12/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucCSSLayoutTableBox.h"

@class EucCSSLayoutTableHeaderGroup, EucCSSLayoutTableFooterGroup;

@interface EucCSSLayoutTableTable : EucCSSLayoutTableBox {
    EucCSSLayoutTableHeaderGroup *_headerGroup;
    NSArray *_rowGroups;
    EucCSSLayoutTableFooterGroup *_footerGroup;
    
    NSArray *_columnGroups;
}

@property (nonatomic, retain) EucCSSLayoutTableHeaderGroup *headerGroup;
@property (nonatomic, retain) NSArray *rowGroups;
@property (nonatomic, retain) EucCSSLayoutTableFooterGroup *footerGroup;

@property (nonatomic, retain) NSArray *columnGroups;

@end
