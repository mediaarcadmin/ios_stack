//
//  EucCSSDocument.h
//  LibCSSTest
//
//  Created by James Montgomerie on 09/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libwapcaplet/libwapcaplet.h>
#import <libcss/libcss.h>
#import "EucHTMLDB.h"

#define EUC_HTML_DOCUMENT_DB_KEY_SHIFT_FOR_FLAGS 3
typedef enum EucCSSDocumentNodeKeyFlags
{
    EucCSSDocumentNodeKeyFlagBeforeContainerNode = 0x1,
    EucCSSDocumentNodeKeyFlagAfterContainerNode  = 0x2,
    EucCSSDocumentNodeKeyFlagGeneratedTextNode   = 0x4,
    
    EucCSSDocumentNodeKeyFlagMask                = 0x7
} EucCSSDocumentNodeKeyFlags;

CGFloat EucCSSLibCSSSizeToPixels(css_computed_style *computed_style, css_fixed size, css_unit units, CGFloat percentageBase);

@class EucCSSDocumentNode, EucCSSDocumentConcreteNode, EucHTMLDBNodeManager, EucHTMLDBNode;

@interface EucCSSDocument : NSObject {
    EucHTMLDB *_db;
    lwc_context *_lwcContext;
    
    EucHTMLDBNodeManager *_manager;
    
    css_select_ctx *_selectCtx;
    
    css_stylesheet **_stylesheets;
    NSInteger _stylesheetsCount;
    
    CFMutableDictionaryRef _keyToExtantNode;
}


- (id)initWithPath:(NSString *)path;
- (EucCSSDocumentNode *)nodeForKey:(uint32_t)key;

@property (nonatomic, retain, readonly) EucCSSDocumentConcreteNode *rootNode;

// Logically package-scope propeties.
@property (nonatomic, readonly) EucHTMLDBNodeManager *htmlDBNodeManager;
@property (nonatomic, readonly) css_select_ctx *selectContext;
@property (nonatomic, readonly) lwc_context *lwcContext;

css_error EucResolveURL(void *pw, lwc_context *dict, const char *base, lwc_string *rel, lwc_string **abs);

// Private - used by EucHTMLDBNode.
- (void)notifyOfDealloc:(EucCSSDocumentNode *)node;

@end
