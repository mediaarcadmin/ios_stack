//
//  EucCSSLayoutPositionedBlock.h
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

@class EucCSSIntermediateDocumentNode;

@interface EucCSSLayoutPositionedBlock : NSObject {
    EucCSSIntermediateDocumentNode *_documentNode;
    EucCSSLayoutPositionedBlock *_parent;
    
    CGRect _frame;
    CGRect _borderRect;
    CGRect _paddingRect;
    CGRect _contentRect;
        
    NSMutableArray *_subEntities;
}

@property (nonatomic, retain) EucCSSIntermediateDocumentNode *documentNode;
@property (nonatomic, assign) EucCSSLayoutPositionedBlock *parent;

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) CGRect borderRect;
@property (nonatomic, assign) CGRect paddingRect;
@property (nonatomic, assign) CGRect contentRect;

@property (nonatomic, retain) NSArray *subEntities;

- (id)initWithDocumentNode:(EucCSSIntermediateDocumentNode *)documentNode;

- (void)positionInFrame:(CGRect)frame afterInternalPageBreak:(BOOL)afterInternalPageBreak;
- (void)closeBottomFromYPoint:(CGFloat)point atInternalPageBreak:(BOOL)atInternalPageBreak;

- (void)addSubEntity:(id)subEntity;

@end
