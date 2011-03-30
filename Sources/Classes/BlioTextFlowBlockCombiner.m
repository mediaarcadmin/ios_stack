//
//  BlioTextBlockCombiner.m
//  BlioApp
//
//  Created by matt on 28/09/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioTextFlowBlockCombiner.h"
#import "BlioTextFlowCombinedBlock.h"

@implementation BlioTextFlowBlockCombiner

#pragma mark -
#pragma mark Wrapper methods

- (BlioTextFlowBlock *)firstCombinedBlockForBlock:(BlioTextFlowBlock *)block
{
    return (BlioTextFlowBlock *)[super firstCombinedBlockForBlock:block];
}

- (BlioTextFlowBlock *)lastCombinedBlockForBlock:(BlioTextFlowBlock *)block
{
    return (BlioTextFlowBlock *)[super lastCombinedBlockForBlock:block];
}

- (CGRect)combinedRectForBlock:(BlioTextFlowBlock *)block
{
    return [super combinedRectForBlock:block];
}

@end
