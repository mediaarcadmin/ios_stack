//
//  EucSelectorRange.h
//  libEucalyptus
//
//  Created by James Montgomerie on 27/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucHighlightRange.h"

@interface EucSelectorRange : NSObject {
    id _startBlockId;
    id _startElementId;
    id _endBlockId;
    id _endElementId;
}

@property (nonatomic, retain) id startBlockId;
@property (nonatomic, retain) id startElementId;
@property (nonatomic, retain) id endBlockId;
@property (nonatomic, retain) id endElementId;

- (BOOL)overlaps:(EucSelectorRange *)otherRange;
- (BOOL)isEqual:(id)object;
- (NSUInteger)hash;

@end

@interface EucHighlightRange (EucSelectorRangeAdditions)

- (EucSelectorRange *)selectorRange;

@end
