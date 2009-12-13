//
//  EucHTMLDocument.h
//  LibCSSTest
//
//  Created by James Montgomerie on 09/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libwapcaplet/libwapcaplet.h>
#import <libcss/libcss.h>
#import "EucHTMLDB.h"

@class EucHTMLDocumentNode, EucHTMLDBNodeManager, EucHTMLDBNode;

@interface EucHTMLDocument : NSObject {
    EucHTMLDB *_db;
    lwc_context *_lwcContext;
    
    EucHTMLDBNodeManager *_manager;
    EucHTMLDBNode *_rootDBNode;
    EucHTMLDBNode *_bodyDBNode;
    
    EucHTMLDocumentNode *_body;
    
    css_select_ctx *_selectCtx;
    
    css_stylesheet **_stylesheets;
    NSInteger _stylesheetsCount;
    
    CFMutableDictionaryRef _keyToExtantNode;
}

@property (nonatomic, readonly) EucHTMLDocumentNode *body;

- (id)initWithPath:(NSString *)path;
- (EucHTMLDocumentNode *)nodeForKey:(uint32_t)key;

// Logically package-scope propeties.
@property (nonatomic, readonly) EucHTMLDBNodeManager *htmlDBNodeManager;
@property (nonatomic, readonly) css_select_ctx *selectContext;

// Private - used by EucHTMLDBNode.
- (void)notifyOfDealloc:(EucHTMLDocumentNode *)node;

@end
