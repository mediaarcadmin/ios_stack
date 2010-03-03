//
//  EucHTMLLayoutPositionedRun.h
//  LibCSSTest
//
//  Created by James Montgomerie on 13/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EucHTMLLayoutDocumentRun, EucHTMLLayoutPositionedBlock;

@interface EucHTMLLayoutPositionedRun : NSObject {
    EucHTMLLayoutDocumentRun *_documentRun;
    EucHTMLLayoutPositionedBlock *_containingBlock;
    NSArray *_lines;
    CGRect _frame;
}

@property (nonatomic, retain, readonly) EucHTMLLayoutDocumentRun *documentRun;
@property (nonatomic, assign) EucHTMLLayoutPositionedBlock *containingBlock;
@property (nonatomic, retain) NSArray *lines;
@property (nonatomic, assign) CGRect frame;

- (id)initWithDocumentRun:(EucHTMLLayoutDocumentRun *)documentRun;

@end
