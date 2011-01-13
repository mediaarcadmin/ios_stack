//
//  BlioTextBlockCombiner.m
//  BlioApp
//
//  Created by matt on 28/09/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioTextFlowBlockCombiner.h"
#import "BlioTextFlow.h"

@interface BlioTextFlowCombinedBlock : NSObject {
    NSMutableArray *blocks;
}

@property (nonatomic, readonly, retain) NSMutableArray *blocks;

- (CGRect)rect;
- (BOOL)containsTextFlowBlock:(BlioTextFlowBlock *)block;

@end

@interface BlioTextFlowBlockCombiner()

@property (nonatomic, retain) NSMutableArray *combinedBlocks;

@end


@implementation BlioTextFlowBlockCombiner

@synthesize verticalSpacing, horizontalSpacing, combinedBlocks;

- (void)dealloc {
    [blocks release];
    [combinedBlocks release];
    [super dealloc];
}

- (id)initWithTextFlowBlocks:(NSArray *)theBlocks {
    if ((self = [super init])) {
        blocks = [theBlocks retain];
        minimumBlockSize = CGSizeZero;
        applyMinimumSize = NO; // experimental
    }
    return self;
}

- (BlioTextFlowBlock *)lastCombinedBlockForBlock:(BlioTextFlowBlock *)block {
    BlioTextFlowBlock *lastBlock = nil;
    
    for (BlioTextFlowCombinedBlock *combinedBlock in self.combinedBlocks) {
        if ([combinedBlock containsTextFlowBlock:block]) {
            lastBlock = [combinedBlock.blocks lastObject];
            break;
        }
    }
    return lastBlock;
}

- (BlioTextFlowBlock *)firstCombinedBlockForBlock:(BlioTextFlowBlock *)block {
    BlioTextFlowBlock *firstBlock = nil;
    
    for (BlioTextFlowCombinedBlock *combinedBlock in self.combinedBlocks) {
        if ([combinedBlock containsTextFlowBlock:block]) {
            firstBlock = [combinedBlock.blocks objectAtIndex:0];
            break;
        }
    }
    return firstBlock;
}

- (CGRect)combinedRectForBlock:(BlioTextFlowBlock *)block {
    CGRect combinedRect = CGRectNull;
    
    for (BlioTextFlowCombinedBlock *combinedBlock in self.combinedBlocks) {
        if ([combinedBlock containsTextFlowBlock:block]) {
            combinedRect = [combinedBlock rect];
            break;
        }
    }
    
    return combinedRect;
}

- (NSArray *)combinedBlocks {
    if (nil == combinedBlocks) {
        combinedBlocks = [[NSMutableArray alloc] init];
        
        for (BlioTextFlowBlock *block in blocks) {
            BOOL intersection = NO;
            
            for (BlioTextFlowCombinedBlock *combinedBlock in combinedBlocks) {
                BlioTextFlowBlock *lastBlock = [combinedBlock.blocks lastObject];
                if (block.blockIndex == (lastBlock.blockIndex + 1)) {
                    CGRect combinedRect = [combinedBlock rect];
                    CGRect blockRect = CGRectInset([block rect], -horizontalSpacing, -verticalSpacing);
                    if (CGRectIntersectsRect(combinedRect, blockRect)) {
                        intersection = YES;
                        [combinedBlock.blocks addObject:block];
                        break;
                    }
                }
            }
            
            if (!intersection) {
                BlioTextFlowCombinedBlock *newCombinedBlock = [[BlioTextFlowCombinedBlock alloc] init];
                [newCombinedBlock.blocks addObject:block];
                [combinedBlocks addObject:newCombinedBlock];
				[newCombinedBlock release];
            }
        }
            
        if (applyMinimumSize) {
            
            CGSize minSize = minimumBlockSize;
            
            if (CGSizeEqualToSize(minSize, CGSizeZero)) {
                minSize = CGSizeMake(MAX(horizontalSpacing, verticalSpacing), MAX(horizontalSpacing, verticalSpacing));
            }
            
            for (BlioTextFlowCombinedBlock *combinedBlock in [NSArray arrayWithArray:combinedBlocks]) {
                if ((CGRectGetWidth([combinedBlock rect]) < minSize.width) &&
                    (CGRectGetHeight([combinedBlock rect]) < minSize.height)) {
                    [combinedBlocks removeObject:combinedBlock];
                }
            }
        }
    }
    
    return combinedBlocks;
}

+ (CGRect)rectByCombiningAllBlocks:(NSArray *)theBlocks {
	
	CGRect combinedRect = CGRectNull;
	
	for (BlioTextFlowBlock *block in theBlocks) {
		combinedRect = CGRectUnion(combinedRect, [block rect]);
	}
	
	return combinedRect;
}

@end

@implementation BlioTextFlowCombinedBlock

@synthesize blocks;

- (void)dealloc {
    [blocks release];
    [super dealloc];
}

- (id)init {
    if ((self = [super init])) {
        blocks = [[NSMutableArray alloc] init];
    }
    return self;
}

- (CGRect)rect {
    CGRect combinedRect = CGRectNull;
    for (BlioTextFlowBlock *block in self.blocks) {
        combinedRect = CGRectUnion(combinedRect, [block rect]);
    }
    return combinedRect;
}

- (BOOL)containsTextFlowBlock:(BlioTextFlowBlock *)aBlock {
    BOOL contains = NO;
    
    // We don't want to compare against nil because block {0, 0} will match
    if (nil == aBlock) {
        return NO;
    }
    
    for (BlioTextFlowBlock *block in self.blocks) {
        if ([aBlock compare:block] == NSOrderedSame) {
            contains = YES;
            break;
        }
    }
    return contains;
}

@end
