//
//  EucHTMLLayoutPositionedBlock.h
//  LibCSSTest
//
//  Created by James Montgomerie on 12/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EucHTMLDocumentNode;

@interface EucHTMLLayoutPositionedBlock : NSObject {
    EucHTMLDocumentNode *_documentNode;

    CGRect _frame;
    CGRect _borderRect;
    CGRect _paddingRect;
    CGRect _contentRect;
        
    NSMutableArray *_subEntities;
}

@property (nonatomic, retain) EucHTMLDocumentNode *documentNode;
@property (nonatomic, assign) EucHTMLLayoutPositionedBlock *parent;

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) CGRect borderRect;
@property (nonatomic, assign) CGRect paddingRect;
@property (nonatomic, assign) CGRect contentRect;

@property (nonatomic, readonly) NSArray *subEntities;

- (id)initWithDocumentNode:(EucHTMLDocumentNode *)documentNode;

- (void)positionInFrame:(CGRect)frame afterInternalPageBreak:(BOOL)afterInternalPageBreak;
- (void)closeBottomFromYPoint:(CGFloat)point atInternalPageBreak:(BOOL)atInternalPageBreak;

- (void)addSubEntity:(id)subEntity;

@end
