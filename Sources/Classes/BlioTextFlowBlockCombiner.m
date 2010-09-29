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
                CGRect combinedRect = [combinedBlock rect];
                CGRect blockRect = CGRectInset([block rect], -horizontalSpacing, -verticalSpacing);
                if (CGRectIntersectsRect(combinedRect, blockRect)) {
                    intersection = YES;
                    [combinedBlock.blocks addObject:block];
                    break;
                }
            }
            
            if (!intersection) {
                BlioTextFlowCombinedBlock *newCombinedBlock = [[BlioTextFlowCombinedBlock alloc] init];
                [newCombinedBlock.blocks addObject:block];
                [combinedBlocks addObject:newCombinedBlock];
            }
        }
    }
    
    return combinedBlocks;
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
    for (BlioTextFlowBlock *block in self.blocks) {
        if (aBlock == block) {
            contains = YES;
            break;
        }
    }
    return contains;
}

@end
