//
//  BlioTextBlockCombiner.h
//  BlioApp
//
//  Created by matt on 28/09/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "KNFBTextFlowBlockCombiner.h"

@class BlioTextFlowBlock;

@interface BlioTextFlowBlockCombiner : KNFBTextFlowBlockCombiner {}

// Wrapper methods
- (BlioTextFlowBlock *)firstCombinedBlockForBlock:(BlioTextFlowBlock *)block;
- (BlioTextFlowBlock *)lastCombinedBlockForBlock:(BlioTextFlowBlock *)block;
- (CGRect)combinedRectForBlock:(BlioTextFlowBlock *)block;

@end
