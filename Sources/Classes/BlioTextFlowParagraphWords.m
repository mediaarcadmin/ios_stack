//
//  BlioTextFlowParagraphWords.m
//  BlioApp
//
//  Created by James Montgomerie on 18/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//


#import "BlioTextFlowParagraphWords.h"

@implementation BlioTextFlowParagraphWords

/* This doesn't appear to be used anywhere
- (BlioBookmarkPoint *)wordOffsetToBookmarkPoint:(uint32_t)wordOffset
{
    NSArray *words;
    if(_ranges.count == 1) {
        words = [_textFlow wordsForBookmarkRange:_ranges.lastObject];
    } else {
        words = [NSMutableArray array];
        for(BlioBookmarkRange *range in _ranges) {
            [(NSMutableArray *)words addObjectsFromArray:[_textFlow wordsForBookmarkRange:range]];
            if(words.count > wordOffset) {
                break;
            }
        }    
    }
    
    BlioTextFlowPositionedWord *word = [words objectAtIndex:wordOffset];
    BlioBookmarkPoint *point = [[BlioBookmarkPoint alloc] init];
    
    point.layoutPage = [BlioTextFlowBlock pageIndexForBlockID:word.blockID];
    point.blockOffset = [BlioTextFlowBlock blockIndexForBlockID:word.blockID];
    point.wordOffset = word.wordIndex;
    
    return [point autorelease];
}
 */

@end
