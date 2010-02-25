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

typedef struct EucHTMLLayoutDocumentRunPoint {
    uint32_t word;
    uint32_t element;
} EucHTMLLayoutDocumentRunPoint;

typedef struct EucHTMLLayoutDocumentRunComponentInfo {
    CGFloat width;
    CGFloat lineHeight;
    CGFloat ascender;
    CGFloat descender;
    CGFloat pointSize;
    EucHTMLDocumentNode *documentNode;
    EucHTMLLayoutDocumentRunPoint point;
} EucHTMLLayoutDocumentRunComponentInfo;

struct EucHTMLLayoutDocumentRunBreakInfo;

@interface EucHTMLLayoutDocumentRun : NSObject {
    uint32_t _id;
    EucHTMLDocumentNode *_startNode;
    EucHTMLDocumentNode *_nextNodeUnderLimitNode;
    EucHTMLDocumentNode *_nextNodeInDocument;

    size_t _componentsCount;
    size_t _componentsCapacity;
    id *_components;
    EucHTMLLayoutDocumentRunComponentInfo *_componentInfos;

    size_t _wordsCount;
    size_t _wordToComponentCapacity;
    uint32_t *_wordToComponent;
    
    uint32_t _currentWordElementCount;
   
    BOOL _previousInlineCharacterWasSpace;
    BOOL _alreadyInsertedNewline;
    
    struct THBreak *_potentialBreaks;
    struct EucHTMLLayoutDocumentRunBreakInfo *_potentialBreakInfos;
    int _potentialBreaksCount;
}

+ (id)singleSpaceMarker;
+ (id)openNodeMarker;
+ (id)closeNodeMarker;
+ (id)hardBreakMarker;

@property (nonatomic, readonly) uint32_t id;
@property (nonatomic, readonly) EucHTMLDocumentNode *nextNodeUnderLimitNode;
@property (nonatomic, readonly) EucHTMLDocumentNode *nextNodeInDocument;

- (id)initWithNode:(EucHTMLDocumentNode *)node 
    underLimitNode:(EucHTMLDocumentNode *)underNode
             forId:(uint32_t)id;

- (EucHTMLLayoutPositionedRun *)positionedRunForFrame:(CGRect)bounds
                                           wordOffset:(uint32_t)wordOffset 
                                        elementOffset:(uint32_t)elementOffset
                                   returningCompleted:(BOOL *)returningCompleted;

@end
