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

@class EucCSSIntermediateDocument, EucCSSLayouter, EucCSSIntermediateDocumentNode, EucCSSLayoutPositionedBlock, EucCSSLayoutPositionedRun, EucSharedHyphenator;
struct THBreak;

typedef struct EucCSSLayoutDocumentRunPoint {
    uint32_t word;
    uint32_t element;
} EucCSSLayoutDocumentRunPoint;

typedef enum EucCSSLayoutDocumentRunComponentKind {
    EucCSSLayoutDocumentRunComponentKindNone = 0,
    EucCSSLayoutDocumentRunComponentKindSpace,
    EucCSSLayoutDocumentRunComponentKindNonbreakingSpace,
    EucCSSLayoutDocumentRunComponentKindHardBreak,
    EucCSSLayoutDocumentRunComponentKindOpenNode,
    EucCSSLayoutDocumentRunComponentKindCloseNode,
    EucCSSLayoutDocumentRunComponentKindWord,
    EucCSSLayoutDocumentRunComponentKindHyphenationRule,
    EucCSSLayoutDocumentRunComponentKindImage,
    EucCSSLayoutDocumentRunComponentKindFloat,
} EucCSSLayoutDocumentRunComponentKind;

typedef struct EucCSSLayoutDocumentRunHyphenationInfo {
    NSString *beforeHyphen;
    CGFloat widthBeforeHyphen;
    NSString *afterHyphen;
    CGFloat widthAfterHyphen;
} EucCSSLayoutDocumentRunHyphenationInfo;


typedef struct EucCSSLayoutDocumentRunImageInfo {
    CGImageRef image;
    CGSize scaledSize;
    CGFloat scaledLineHeight;
} EucCSSLayoutDocumentRunImageInfo;


typedef struct EucCSSLayoutDocumentRunComponentInfo {
    EucCSSLayoutDocumentRunComponentKind kind;
    EucCSSLayoutDocumentRunPoint point;
    EucCSSIntermediateDocumentNode *documentNode;
    CGFloat width;
    union {
        NSString *string;
        EucCSSLayoutDocumentRunHyphenationInfo hyphenationInfo;
        EucCSSLayoutDocumentRunImageInfo imageInfo;
    } contents;
} EucCSSLayoutDocumentRunComponentInfo;

struct EucCSSLayoutDocumentRunBreakInfo;

@interface EucCSSLayoutDocumentRun : NSObject {
    uint32_t _id;
    
    EucCSSIntermediateDocument *_document;
    
    EucCSSIntermediateDocumentNode *_startNode;
    EucCSSIntermediateDocumentNode *_underNode;
    
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
    UniChar _characterBeforeWord;
    BOOL _alreadyInsertedSpace;
    BOOL _seenNonSpace;
    
    NSMutableArray *_sizeDependentComponentIndexes;
    NSMutableArray *_floatComponentIndexes;

    struct THBreak *_potentialBreaks;
    struct EucCSSLayoutDocumentRunBreakInfo *_potentialBreakInfos;
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
+ (id)documentRunWithNode:(EucCSSIntermediateDocumentNode *)inlineNode 
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

- (EucCSSLayoutDocumentRunPoint)pointForNode:(EucCSSIntermediateDocumentNode *)node;

- (NSArray *)words;
- (NSArray *)attributeValuesForWordsForAttributeName:(NSString *)attribute;

@end