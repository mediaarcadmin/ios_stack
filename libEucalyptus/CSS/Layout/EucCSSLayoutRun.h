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

#import "EucCSSIntermediateDocumentNode.h"

@class EucCSSIntermediateDocument, EucCSSLayouter, EucCSSLayoutPositionedBlock, EucCSSLayoutPositionedRun, EucSharedHyphenator;
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
    NSString *afterHyphen;
} EucCSSLayoutRunHyphenationInfo;

typedef struct EucCSSLayoutRunImageInfo {
    NSURL *imageURL;
} EucCSSLayoutRunImageInfo;

typedef struct EucCSSLayoutRunComponentInfo {
    EucCSSLayoutRunComponentKind kind;
    EucCSSLayoutRunPoint point;
    EucCSSIntermediateDocumentNode *documentNode;
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
        
    size_t _componentsCount;
    size_t _componentsCapacity;
    EucCSSLayoutRunComponentInfo *_componentInfos;
    
    uint32_t _wordsCount;
    size_t _wordToComponentCapacity;
    uint32_t *_wordToComponent;
    
    uint32_t _currentWordElementCount;
    
    BOOL _previousInlineCharacterWasSpace;
    UniChar _characterBeforeWord;
    BOOL _alreadyInsertedSpace;
    BOOL _seenNonSpace;
    
    NSMutableArray *_sizeDependentComponentIndexes;
    NSMutableArray *_floatComponentIndexes;
    
    EucSharedHyphenator *_sharedHyphenator;
}

@property (nonatomic, assign, readonly) uint32_t id;
@property (nonatomic, retain, readonly) EucCSSIntermediateDocument *document;
@property (nonatomic, retain, readonly) EucCSSIntermediateDocumentNode *startNode;
@property (nonatomic, retain, readonly) EucCSSIntermediateDocumentNode *underNode;
@property (nonatomic, retain, readonly) EucCSSIntermediateDocumentNode *nextNodeUnderLimitNode;
@property (nonatomic, retain, readonly) EucCSSIntermediateDocumentNode *nextNodeInDocument;

@property (nonatomic, assign, readonly) uint8_t textAlign;
- (CGFloat)textIndentInWidth:(CGFloat)width initWithScaleFactor:(CGFloat)scaleFactor;


// This convenience constructor will return a cached node if one with the same
// attibutes was requested recently.
+ (id)runWithNode:(EucCSSIntermediateDocumentNode *)inlineNode 
   underLimitNode:(EucCSSIntermediateDocumentNode *)underNode
   stopBeforeNode:(EucCSSIntermediateDocumentNode *)stopBeforeNode
            forId:(uint32_t)id;

- (id)initWithNode:(EucCSSIntermediateDocumentNode *)node 
    underLimitNode:(EucCSSIntermediateDocumentNode *)underNode
    stopBeforeNode:(EucCSSIntermediateDocumentNode *)stopBeforeNode
             forId:(uint32_t)id;

- (EucCSSLayoutRunPoint)pointForNode:(EucCSSIntermediateDocumentNode *)node;

@property (nonatomic, assign, readonly) uint32_t wordsCount;
- (NSArray *)words;
- (NSArray *)attributeValuesForWordsForAttributeName:(NSString *)attribute;

@end

@interface EucCSSIntermediateDocumentNode (EusCSSLayoutRunAdditions) 

@property (nonatomic, assign, readonly) BOOL isLayoutRunBreaker;

@end