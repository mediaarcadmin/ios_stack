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

@class EucCSSIntermediateDocumentNode, EucCSSLayoutPositionedRun;
struct THBreak;

typedef struct EucCSSLayoutDocumentRunPoint {
    uint32_t word;
    uint32_t element;
} EucCSSLayoutDocumentRunPoint;

typedef struct EucCSSLayoutDocumentRunComponentInfo {
    CGFloat width;
    CGFloat lineHeight;
    CGFloat ascender;
    CGFloat descender;
    CGFloat pointSize;
    EucCSSIntermediateDocumentNode *documentNode;
    EucCSSLayoutDocumentRunPoint point;
} EucCSSLayoutDocumentRunComponentInfo;

struct EucCSSLayoutDocumentRunBreakInfo;

@interface EucCSSLayoutDocumentRun : NSObject {
    uint32_t _id;
    EucCSSIntermediateDocumentNode *_startNode;
    EucCSSIntermediateDocumentNode *_nextNodeUnderLimitNode;
    EucCSSIntermediateDocumentNode *_nextNodeInDocument;

    size_t _componentsCount;
    size_t _componentsCapacity;
    id *_components;
    EucCSSLayoutDocumentRunComponentInfo *_componentInfos;

    size_t _wordsCount;
    size_t _wordToComponentCapacity;
    uint32_t *_wordToComponent;
    
    uint32_t _currentWordElementCount;
   
    BOOL _previousInlineCharacterWasSpace;
    BOOL _alreadyInsertedNewline;
    
    struct THBreak *_potentialBreaks;
    struct EucCSSLayoutDocumentRunBreakInfo *_potentialBreakInfos;
    int _potentialBreaksCount;
}

+ (id)singleSpaceMarker;
+ (id)openNodeMarker;
+ (id)closeNodeMarker;
+ (id)hardBreakMarker;

@property (nonatomic, readonly) uint32_t id;
@property (nonatomic, readonly) EucCSSIntermediateDocumentNode *nextNodeUnderLimitNode;
@property (nonatomic, readonly) EucCSSIntermediateDocumentNode *nextNodeInDocument;

- (id)initWithNode:(EucCSSIntermediateDocumentNode *)node 
    underLimitNode:(EucCSSIntermediateDocumentNode *)underNode
             forId:(uint32_t)id;

- (EucCSSLayoutPositionedRun *)positionedRunForFrame:(CGRect)bounds
                                           wordOffset:(uint32_t)wordOffset 
                                        elementOffset:(uint32_t)elementOffset;

@end
