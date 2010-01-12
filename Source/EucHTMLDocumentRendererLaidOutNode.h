//
//  EucHTMLDocumentRendererLaidOutNode.h
//  LibCSSTest
//
//  Created by James Montgomerie on 10/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EucHTMLDocumentNode;

extern const id const EucHTMLRendererSingleSpaceMarker;
extern const id const EucHTMLRendererOpenNodeMarker;
extern const id const EucHTMLRendererCloseNodeMarker;

@interface EucHTMLDocumentRendererLaidOutNode : NSObject {
    EucHTMLDocumentNode *_documentNode;
    CGRect _frame;

    NSMutableArray *_children;

    NSArray *_lineContents;
}

@property (nonatomic, retain) EucHTMLDocumentNode *documentNode;
@property (nonatomic, retain) int32_t wordOffset;
@property (nonatomic, retain) int32_t hyphenOffset;

// Child nodes.  May be nil.
@property (nonatomic, readonly) NSArray *children;
- (void)addChild:(EucHTMLDocumentRendererLaidOutNode *)child;

// For line nodes only, strings and an equal length array of the document nodes
// they were originally 'in'.
@property (nonatomic, retain) NSArray *lineContents;

@property (nonatomic, assign) CGRect frame;
- (void)sizeToFit;
- (void)sizeToFitHorizontally;

@end
