//
//  EucCSSLayoutDocumentRun.h
//  LibCSSTest
//
//  Created by James Montgomerie on 12/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif

@class EucCSSIntermediateDocumentNode, EucCSSLayoutPositionedRun, EucSharedHyphenator;
struct THBreak;

typedef struct EucCSSLayoutDocumentRunPoint {
    uint32_t word;
    uint32_t element;
} EucCSSLayoutDocumentRunPoint;

typedef enum EucCSSLayoutDocumentRunComponentKind {
    EucCSSLayoutDocumentRunComponentKindNone = 0,
    EucCSSLayoutDocumentRunComponentKindSpace,
    EucCSSLayoutDocumentRunComponentKindHardBreak,
    EucCSSLayoutDocumentRunComponentKindOpenNode,
    EucCSSLayoutDocumentRunComponentKindCloseNode,
    EucCSSLayoutDocumentRunComponentKindWord,
    EucCSSLayoutDocumentRunComponentKindHyphenationRule,
    EucCSSLayoutDocumentRunComponentKindImage,
} EucCSSLayoutDocumentRunComponentKind;

typedef struct EucCSSLayoutDocumentRunComponentInfo {
    EucCSSLayoutDocumentRunComponentKind kind;
    void *component;
    void *component2;
    CGFloat pointSize;
    CGFloat width;
    CGFloat widthBeforeHyphen;
    CGFloat widthAfterHyphen;
    CGFloat ascender;
    CGFloat lineHeight;
    EucCSSIntermediateDocumentNode *documentNode;
    EucCSSLayoutDocumentRunPoint point;
} EucCSSLayoutDocumentRunComponentInfo;

struct EucCSSLayoutDocumentRunBreakInfo;

@interface EucCSSLayoutDocumentRun : NSObject {
    uint32_t _id;
    
    EucCSSIntermediateDocumentNode *_startNode;
    EucCSSIntermediateDocumentNode *_nextNodeUnderLimitNode;
    EucCSSIntermediateDocumentNode *_nextNodeInDocument;

    CGFloat _scaleFactor;
    
    size_t _componentsCount;
    size_t _componentsCapacity;
    EucCSSLayoutDocumentRunComponentInfo *_componentInfos;

    size_t _wordsCount;
    size_t _wordToComponentCapacity;
    uint32_t *_wordToComponent;
    
    uint32_t _currentWordElementCount;
   
    BOOL _previousInlineCharacterWasSpace;
    BOOL _alreadyInsertedSpace;
    BOOL _seenNonSpace;
    
    NSMutableArray *_sizeDependentComponentIndexes;
    
    struct THBreak *_potentialBreaks;
    struct EucCSSLayoutDocumentRunBreakInfo *_potentialBreakInfos;
    int _potentialBreaksCount;
    
    EucSharedHyphenator *_sharedHyphenator;
}

@property (nonatomic, readonly) uint32_t id;
@property (nonatomic, readonly) EucCSSIntermediateDocumentNode *nextNodeUnderLimitNode;
@property (nonatomic, readonly) EucCSSIntermediateDocumentNode *nextNodeInDocument;

- (id)initWithNode:(EucCSSIntermediateDocumentNode *)node 
    underLimitNode:(EucCSSIntermediateDocumentNode *)underNode
             forId:(uint32_t)id
       scaleFactor:(CGFloat)scaleFactor;

- (EucCSSLayoutPositionedRun *)positionedRunForFrame:(CGRect)bounds
                                          wordOffset:(uint32_t)wordOffset 
                                       elementOffset:(uint32_t)elementOffset;

- (EucCSSLayoutDocumentRunPoint)pointForNode:(EucCSSIntermediateDocumentNode *)node;

@end