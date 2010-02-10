//
//  EucHTMLLayoutPositionedRun.h
//  LibCSSTest
//
//  Created by James Montgomerie on 13/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EucHTMLLayoutDocumentRun;

@interface EucHTMLLayoutPositionedRun : NSObject {
    EucHTMLLayoutDocumentRun *_documentRun;
    NSArray *_lines;
    CGRect _frame;
}

@property (nonatomic, readonly) EucHTMLLayoutDocumentRun *documentRun;
@property (nonatomic, readonly) NSArray *lines;
@property (nonatomic, readonly) CGRect frame;

- (id)initWithDocumentRun:(EucHTMLLayoutDocumentRun *)documentRun
                    lines:(NSArray *)lines
                    frame:(CGRect)frame;

@end
