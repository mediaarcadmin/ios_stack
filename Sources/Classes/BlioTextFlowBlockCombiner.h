//
//  BlioTextBlockCombiner.h
//  BlioApp
//
//  Created by matt on 28/09/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BlioTextFlowBlock;

@interface BlioTextFlowBlockCombiner : NSObject {
    NSArray *blocks;
    NSMutableArray *combinedBlocks;
    CGFloat verticalSpacing;
    CGFloat horizontalSpacing;
    CGSize minimumBlockSize;
    BOOL applyMinimumSize;
}

@property (nonatomic, assign) CGFloat verticalSpacing;
@property (nonatomic, assign) CGFloat horizontalSpacing;

- (id)initWithTextFlowBlocks:(NSArray *)theBlocks;
- (BlioTextFlowBlock *)firstCombinedBlockForBlock:(BlioTextFlowBlock *)block;
- (BlioTextFlowBlock *)lastCombinedBlockForBlock:(BlioTextFlowBlock *)block;
- (CGRect)combinedRectForBlock:(BlioTextFlowBlock *)block;

+ (CGRect)rectByCombiningAllBlocks:(NSArray *)theBlocks;

@end
