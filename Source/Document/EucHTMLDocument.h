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

CGFloat libcss_size_to_pixels(css_computed_style *computed_style, css_fixed size, css_unit units, CGFloat percentageBase);

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

- (BOOL)nodeIsBody:(EucHTMLDocumentNode *)node;

// Logically package-scope propeties.
@property (nonatomic, readonly) EucHTMLDBNodeManager *htmlDBNodeManager;
@property (nonatomic, readonly) css_select_ctx *selectContext;
@property (nonatomic, readonly) lwc_context *lwcContext;

css_error EucResolveURL(void *pw, lwc_context *dict, const char *base, lwc_string *rel, lwc_string **abs);

// Private - used by EucHTMLDBNode.
- (void)notifyOfDealloc:(EucHTMLDocumentNode *)node;

@end
