//
//  EucCSSIntermediateDocument.h
//  LibCSSTest
//
//  Created by James Montgomerie on 09/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif
#import <libwapcaplet/libwapcaplet.h>
#import <libcss/libcss.h>

#define EUC_HTML_DOCUMENT_DB_KEY_SHIFT_FOR_FLAGS 3
typedef enum EucCSSIntermediateDocumentNodeKeyFlags
{
    EucCSSIntermediateDocumentNodeKeyFlagBeforeContainerNode = 0x1,
    EucCSSIntermediateDocumentNodeKeyFlagAfterContainerNode  = 0x2,
    EucCSSIntermediateDocumentNodeKeyFlagGeneratedTextNode   = 0x4,
    
    EucCSSIntermediateDocumentNodeKeyFlagMask                = 0x7
} EucCSSIntermediateDocumentNodeKeyFlags;

CGFloat EucCSSLibCSSSizeToPixels(css_computed_style *computed_style, css_fixed size, css_unit units, CGFloat percentageBase);

@class EucCSSIntermediateDocumentNode, EucCSSIntermediateDocumentConcreteNode;
@protocol EucCSSDocumentTree;

@interface EucCSSIntermediateDocument : NSObject {
    id<EucCSSDocumentTree> _documentTree;
    lwc_context *_lwcContext;
    
    css_select_ctx *_selectCtx;
    
    css_stylesheet **_stylesheets;
    NSInteger _stylesheetsCount;
    
    CFMutableDictionaryRef _keyToExtantNode;
}


- (id)initWithDocumentTree:(id<EucCSSDocumentTree>)documentTree
               baseCSSPath:(NSString *)baseCSSPath;
- (id)initWithDocumentTree:(id<EucCSSDocumentTree>)documentTree 
               baseCSSPath:(NSString *)baseCSSPath
                lwcContext:(lwc_context *)lwcContext;


- (EucCSSIntermediateDocumentNode *)nodeForKey:(uint32_t)key;

@property (nonatomic, retain, readonly) EucCSSIntermediateDocumentConcreteNode *rootNode;

// Logically package-scope propeties.
@property (nonatomic, readonly) id<EucCSSDocumentTree> documentTree;
@property (nonatomic, readonly) css_select_ctx *selectContext;
@property (nonatomic, readonly) lwc_context *lwcContext;

css_error EucResolveURL(void *pw, lwc_context *dict, const char *base, lwc_string *rel, lwc_string **abs);

// Private - used by EucHTMLDBNode.
- (void)notifyOfDealloc:(EucCSSIntermediateDocumentNode *)node;

@end
