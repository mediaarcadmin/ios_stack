//
//  EucCSSLayoutRun.h
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

@class EucCSSIntermediateDocument, EucCSSLayouter, EucCSSIntermediateDocumentNode, EucCSSLayoutPositionedBlock, EucCSSLayoutPositionedRun, EucSharedHyphenator;
struct THBreak;

typedef struct EucCSSLayoutRunPoint {
    uint32_t word;
    uint32_t element;
} EucCSSLayoutRunPoint;

typedef enum EucCSSLayoutRunComponentKind {
    EucCSSLayoutRunComponentKindNone = 0,
    EucCSSLayoutRunComponentKindSpace,
    EucCSSLayoutRunComponentKindNonbreakingSpace,
    EucCSSLayoutRunComponentKindHardBreak,
    EucCSSLayoutRunComponentKindWord,
    EucCSSLayoutRunComponentKindHyphenationRule,
    EucCSSLayoutRunComponentKindImage,
    EucCSSLayoutRunComponentKindOpenNode,
    EucCSSLayoutRunComponentKindCloseNode,
    EucCSSLayoutRunComponentKindFloat,
} EucCSSLayoutRunComponentKind;

typedef struct EucCSSLayoutRunStringInfo {
    NSString *string;
} EucCSSLayoutRunStringInfo;

typedef struct EucCSSLayoutRunHyphenationInfo {
    NSString *beforeHyphen;
    CGFloat widthBeforeHyphen;
    NSString *afterHyphen;
    CGFloat widthAfterHyphen;
} EucCSSLayoutRunHyphenationInfo;

typedef struct EucCSSLayoutRunImageInfo {
    CGImageRef image;
    CGSize scaledSize;
    CGFloat scaledLineHeight;
} EucCSSLayoutRunImageInfo;

typedef struct EucCSSLayoutRunComponentInfo {
    EucCSSLayoutRunComponentKind kind;
    EucCSSLayoutRunPoint point;
    EucCSSIntermediateDocumentNode *documentNode;
    CGFloat width;
    union {
        EucCSSLayoutRunStringInfo stringInfo;
        EucCSSLayoutRunHyphenationInfo hyphenationInfo;
        EucCSSLayoutRunImageInfo imageInfo;
    } contents;
} EucCSSLayoutRunComponentInfo;

struct EucCSSLayoutRunBreakInfo;

@interface EucCSSLayoutRun : NSObject {
    uint32_t _id;
    
    EucCSSIntermediateDocument *_document;
    
    EucCSSIntermediateDocumentNode *_startNode;
    EucCSSIntermediateDocumentNode *_underNode;
    
    EucCSSIntermediateDocumentNode *_nextNodeUnderLimitNode;
    EucCSSIntermediateDocumentNode *_nextNodeInDocument;
    
    CGFloat _scaleFactor;
    
    size_t _componentsCount;
    size_t _componentsCapacity;
    EucCSSLayoutRunComponentInfo *_componentInfos;
    
    size_t _wordsCount;
    size_t _wordToComponentCapacity;
    uint32_t *_wordToComponent;
    
    uint32_t _currentWordElementCount;
    
    BOOL _previousInlineCharacterWasSpace;
    UniChar _characterBeforeWord;
    BOOL _alreadyInsertedSpace;
    BOOL _seenNonSpace;
    
    NSMutableArray *_sizeDependentComponentIndexes;
    NSMutableArray *_floatComponentIndexes;
    
    struct THBreak *_potentialBreaks;
    struct EucCSSLayoutRunBreakInfo *_potentialBreakInfos;
    int _potentialBreaksCount;
    
    EucSharedHyphenator *_sharedHyphenator;
}

@property (nonatomic, assign, readonly) uint32_t id;
@property (nonatomic, retain, readonly) EucCSSIntermediateDocumentNode *startNode;
@property (nonatomic, retain, readonly) EucCSSIntermediateDocumentNode *underNode;
@property (nonatomic, retain, readonly) EucCSSIntermediateDocumentNode *nextNodeUnderLimitNode;
@property (nonatomic, retain, readonly) EucCSSIntermediateDocumentNode *nextNodeInDocument;
@property (nonatomic, assign, readonly) CGFloat scaleFactor;

// This convenience constructor will return a cached node if one with the same
// attibutes was requested recently.
+ (id)runWithNode:(EucCSSIntermediateDocumentNode *)inlineNode 
           underLimitNode:(EucCSSIntermediateDocumentNode *)underNode
forId:(uint32_t)id
scaleFactor:(CGFloat)scaleFactor;

- (id)initWithNode:(EucCSSIntermediateDocumentNode *)node 
    underLimitNode:(EucCSSIntermediateDocumentNode *)underNode
forId:(uint32_t)id
scaleFactor:(CGFloat)scaleFactor;

- (EucCSSLayoutPositionedRun *)positionRunForFrame:(CGRect)frame
                                       inContainer:(EucCSSLayoutPositionedBlock *)container
                              startingAtWordOffset:(uint32_t)wordOffset 
                                     elementOffset:(uint32_t)elementOffset
                            usingLayouterForFloats:(EucCSSLayouter *)layouter;

- (EucCSSLayoutRunPoint)pointForNode:(EucCSSIntermediateDocumentNode *)node;

- (NSArray *)words;
- (NSArray *)attributeValuesForWordsForAttributeName:(NSString *)attribute;

@end