//
//  EucHTMLLayoutDocumentRun.h
//  LibCSSTest
//
//  Created by James Montgomerie on 12/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EucHTMLDocumentNode, EucHTMLLayoutPositionedRun;
struct THBreak;

typedef struct EucHTMLLayoutDocumentRunComponentInfo {
    CGFloat width;
    CGFloat lineHeight;
    CGFloat ascender;
    CGFloat descender;
    CGFloat pointSize;
    EucHTMLDocumentNode *documentNode;
} EucHTMLLayoutDocumentRunComponentInfo;

@interface EucHTMLLayoutDocumentRun : NSObject {
    uint32_t _id;
    EucHTMLDocumentNode *_startNode;
    EucHTMLDocumentNode *_nextNodeUnderLimitNode;
    EucHTMLDocumentNode *_nextNodeInDocument;

    
    size_t _componentsCount;
    size_t _componentsCapacity;
    id *_components;
    EucHTMLLayoutDocumentRunComponentInfo *_componentInfos;
    size_t *_componentOffsetToWordOffset;

    size_t _wordsCount;
    size_t *_wordOffsetToComponentOffset;
    size_t _startOfLastNonSpaceRun;

    BOOL _previousInlineCharacterWasSpace;
    BOOL _alreadyInsertedNewline;
    
    struct THBreak *_potentialBreaks;
    int *_potentialBreakToComponentOffset;
    int _potentialBreaksCount;
}

+ (id)singleSpaceMarker;
+ (id)openNodeMarker;
+ (id)closeNodeMarker;

@property (nonatomic, readonly) uint32_t id;
@property (nonatomic, readonly) EucHTMLDocumentNode *nextNodeUnderLimitNode;
@property (nonatomic, readonly) EucHTMLDocumentNode *nextNodeInDocument;

@property (nonatomic, readonly) id *components;
@property (nonatomic, readonly) EucHTMLLayoutDocumentRunComponentInfo *componentInfos;

- (id)initWithNode:(EucHTMLDocumentNode *)node 
    underLimitNode:(EucHTMLDocumentNode *)underNode
             forId:(uint32_t)id;

- (EucHTMLLayoutPositionedRun *)positionedRunForFrame:(CGRect)bounds
                                           wordOffset:(uint32_t)wordOffset 
                                         hyphenOffset:(uint32_t)hyphenOffset;    

@end
