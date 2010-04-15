//
//  BlioTextFlowParagraphSource.m
//  BlioApp
//
//  Created by James Montgomerie on 14/04/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioTextFlowParagraphSource.h"

#import "BlioTextFlow.h"
#import "BlioTextFlowFlowTree.h"
#import "BlioTextFlowParagraph.h"
#import "BlioTextFlowParagraphWords.h"

@interface BlioTextFlowParagraphSource ()

@property (nonatomic, assign) NSUInteger currentFlowTreeSection;
@property (nonatomic, retain) BlioTextFlowFlowTree *currentFlowTree;

@end


@implementation BlioTextFlowParagraphSource

@synthesize textFlow;

@synthesize currentFlowTreeSection;
@synthesize currentFlowTree;

- (id)initWithTextFlow:(BlioTextFlow *)textFlowIn
{
    if((self = [super init])) {
        textFlow = [textFlowIn retain];
    }
    return self;
}

- (void)dealloc
{
    [textFlow release];
    [currentFlowTree release];
    
    [super dealloc];
}

- (BlioTextFlowFlowTree *)flowFlowTreeForSection:(NSUInteger)section
{
    if(section != self.currentFlowTreeSection || !self.currentFlowTree) {
        self.currentFlowTree = [self.textFlow flowTreeForSectionIndex:section];
        self.currentFlowTreeSection = section;
    }    
    return self.currentFlowTree;
}

- (BlioTextFlowParagraph *)paragraphWithID:(NSIndexPath *)paragraphID
{
    BlioTextFlowFlowTree *flowFlowTree = [self flowFlowTreeForSection:[paragraphID indexAtPosition:0]];
    
    uint32_t key = [paragraphID indexAtPosition:1];
    if(key) {
        return (BlioTextFlowParagraph *)[flowFlowTree nodeForKey:[paragraphID indexAtPosition:1]];
    } else {
        return flowFlowTree.firstParagraph;
    }
}

- (void)bookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint toParagraphID:(id *)paragraphID wordOffset:(uint32_t *)wordOffset
{
    NSUInteger sectionIndex = 0;
    NSUInteger bookmarkPageIndex = bookmarkPoint.layoutPage - 1;
    NSArray *sections = self.textFlow.sections;
    BlioTextFlowSection *bestSection = [sections objectAtIndex:0];
    NSUInteger nextSectionIndex = 0;
    for(BlioTextFlowSection *section in sections) {
        if(section.startPage <= bookmarkPageIndex) {
            bestSection = section;
            sectionIndex = nextSectionIndex;
            ++nextSectionIndex;
        } else {
            break;
        }
    }
    
    BlioTextFlowFlowTree *flowFlowTree = [self flowFlowTreeForSection:sectionIndex];
    BlioTextFlowParagraph *bestParagraph = flowFlowTree.firstParagraph;

    BOOL stop = NO;
    BlioTextFlowParagraph *nextParagraph;
    while(!stop && (nextParagraph = bestParagraph.nextSibling)) {
        NSArray *ranges = nextParagraph.paragraphWords.ranges;
        if(ranges.count) {
            BlioBookmarkRange *range = [nextParagraph.paragraphWords.ranges objectAtIndex:0];
            BlioBookmarkPoint *startPoint = range.startPoint;
            if([startPoint compare:bookmarkPoint] == NSOrderedDescending) {
                break;
            }
        }
        bestParagraph = nextParagraph;
    }
    
    NSUInteger indexes[2] = { sectionIndex, bestParagraph.key };
    *paragraphID = [NSIndexPath indexPathWithIndexes:indexes length:2];
    
    uint32_t bestWordOffset = 0;
    BlioBookmarkPoint *comparisonPoint = [[BlioBookmarkPoint alloc] init];
    for(BlioTextFlowPositionedWord *word in bestParagraph.paragraphWords.words) {
        comparisonPoint.layoutPage = [BlioTextFlowBlock pageIndexForBlockID:word.blockID] + 1;
        comparisonPoint.blockOffset = [BlioTextFlowBlock blockIndexForBlockID:word.blockID];
        comparisonPoint.wordOffset = word.wordIndex;
        if([comparisonPoint compare:bookmarkPoint] <= NSOrderedSame) {
            ++bestWordOffset;
        } else {
            break;
        }
    }
    if(bestWordOffset) {
        bestWordOffset--;
    }
    [comparisonPoint release];
    
    *wordOffset = bestWordOffset;
}

- (BlioBookmarkPoint *)bookmarkPointFromParagraphID:(id)paragraphID wordOffset:(uint32_t)wordOffset
{
    BlioTextFlowParagraph *paragraph = [self paragraphWithID:(NSIndexPath *)paragraphID];
    BlioTextFlowParagraphWords *paragraphWords = paragraph.paragraphWords;
    NSArray *words = paragraphWords.words;

    BlioTextFlowPositionedWord *word = [words objectAtIndex:wordOffset];
    
    BlioBookmarkPoint * ret = [[BlioBookmarkPoint alloc] init];

    ret.layoutPage = [BlioTextFlowBlock pageIndexForBlockID:word.blockID] + 1;
    ret.blockOffset = [BlioTextFlowBlock blockIndexForBlockID:word.blockID];
    ret.wordOffset = word.wordIndex;

    return [ret autorelease];
}

- (NSArray *)wordsForParagraphWithID:(id)paragraphID
{
    BlioTextFlowParagraph *paragraph = [self paragraphWithID:(NSIndexPath *)paragraphID];
    return paragraph.paragraphWords.wordStrings;
}

- (id)nextParagraphIdForParagraphWithID:(id)paragraphID
{
    NSIndexPath *ret = nil;
    
    BlioTextFlowParagraph *paragraph = [self paragraphWithID:(NSIndexPath *)paragraphID];
    paragraph = paragraph.nextSibling;
    
    if(!paragraph) {
        NSUInteger indexes[2] = { [paragraphID indexAtPosition:0] + 1, 0 };
        NSIndexPath *newID = [[NSIndexPath alloc] initWithIndexes:indexes length:2];
        paragraph = [self paragraphWithID:newID];
        [newID release];
    }
    
    if(paragraph) {
        NSUInteger indexes[2] = { [paragraphID indexAtPosition:0], (NSUInteger)paragraph.key };
        ret = [NSIndexPath indexPathWithIndexes:indexes length:2];
    }
    
    return ret;
}

@end
