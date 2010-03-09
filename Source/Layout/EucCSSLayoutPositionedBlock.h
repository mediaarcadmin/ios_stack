//
//  EucCSSLayoutPositionedBlock.h
//  LibCSSTest
//
//  Created by James Montgomerie on 12/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EucCSSDocumentNode;

@interface EucCSSLayoutPositionedBlock : NSObject {
    EucCSSDocumentNode *_documentNode;

    CGRect _frame;
    CGRect _borderRect;
    CGRect _paddingRect;
    CGRect _contentRect;
        
    NSMutableArray *_subEntities;
}

@property (nonatomic, retain) EucCSSDocumentNode *documentNode;
@property (nonatomic, assign) EucCSSLayoutPositionedBlock *parent;

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) CGRect borderRect;
@property (nonatomic, assign) CGRect paddingRect;
@property (nonatomic, assign) CGRect contentRect;

@property (nonatomic, retain) NSArray *subEntities;

- (id)initWithDocumentNode:(EucCSSDocumentNode *)documentNode;

- (void)positionInFrame:(CGRect)frame afterInternalPageBreak:(BOOL)afterInternalPageBreak;
- (void)closeBottomFromYPoint:(CGFloat)point atInternalPageBreak:(BOOL)atInternalPageBreak;

- (void)addSubEntity:(id)subEntity;

@end
