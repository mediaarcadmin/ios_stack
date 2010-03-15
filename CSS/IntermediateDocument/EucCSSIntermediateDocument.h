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

struct lwc_context_s;
struct css_select_ctx;
struct css_stylesheet;

#define EUC_HTML_DOCUMENT_DB_KEY_SHIFT_FOR_FLAGS 3
typedef enum EucCSSIntermediateDocumentNodeKeyFlags
{
    EucCSSIntermediateDocumentNodeKeyFlagBeforeContainerNode = 0x1,
    EucCSSIntermediateDocumentNodeKeyFlagAfterContainerNode  = 0x2,
    EucCSSIntermediateDocumentNodeKeyFlagGeneratedTextNode   = 0x4,
    
    EucCSSIntermediateDocumentNodeKeyFlagMask                = 0x7
} EucCSSIntermediateDocumentNodeKeyFlags;

@class EucCSSIntermediateDocumentNode, EucCSSIntermediateDocumentConcreteNode;
@protocol EucCSSDocumentTree;

@interface EucCSSIntermediateDocument : NSObject {
    id<EucCSSDocumentTree> _documentTree;
    struct lwc_context_s *_lwcContext;
    
    struct css_select_ctx *_selectCtx;
    
    struct css_stylesheet **_stylesheets;
    NSInteger _stylesheetsCount;
    
    CFMutableDictionaryRef _keyToExtantNode;
}


- (id)initWithDocumentTree:(id<EucCSSDocumentTree>)documentTree
               baseCSSPath:(NSString *)baseCSSPath;

- (EucCSSIntermediateDocumentNode *)nodeForKey:(uint32_t)key;
- (uint32_t)nodeKeyForId:(NSString *)identifier;

@property (nonatomic, retain, readonly) EucCSSIntermediateDocumentNode *rootNode;

@end
