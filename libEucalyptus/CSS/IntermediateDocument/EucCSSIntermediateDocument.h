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

struct css_select_ctx;
struct css_stylesheet;

@class EucCSSIntermediateDocumentNode, EucCSSIntermediateDocumentConcreteNode, THIntegerToObjectCache;
@protocol EucCSSDocumentTree, EucCSSIntermediateDocumentDataProvider;

@interface EucCSSIntermediateDocument : NSObject {
    id<EucCSSDocumentTree> _documentTree;
    NSURL *_url;
    id<EucCSSIntermediateDocumentDataProvider> _dataSource;
    
    struct css_select_ctx *_selectCtx;
    
    struct css_stylesheet **_stylesheets;
    NSInteger _stylesheetsCount;
    
    THIntegerToObjectCache *_keyToExtantNode;
}


- (id)initWithDocumentTree:(id<EucCSSDocumentTree>)documentTree
                    forURL:(NSURL *)url
                dataSource:(id<EucCSSIntermediateDocumentDataProvider>)dataSource
              baseCSSPaths:(NSArray *)baseCSSPaths
              userCSSPaths:(NSArray *)userCSSPaths;

- (EucCSSIntermediateDocumentNode *)nodeForKey:(uint32_t)key;
- (uint32_t)nodeKeyForId:(NSString *)identifier;

+ (uint32_t)documentTreeNodeKeyForKey:(uint32_t)key;
+ (uint32_t)keyForDocumentTreeNodeKey:(uint32_t)key;
- (float)estimatedPercentageForNodeWithKey:(uint32_t)key;

- (NSData *)dataForURL:(NSURL *)url;
- (CGImageRef)imageForURL:(NSURL *)url;

@property (nonatomic, retain, readonly) id<EucCSSDocumentTree> documentTree;
@property (nonatomic, retain, readonly) EucCSSIntermediateDocumentNode *rootNode;
@property (nonatomic, retain, readonly) NSURL *url;
@property (nonatomic, assign, readonly) id<EucCSSIntermediateDocumentDataProvider> dataSource;
@property (nonatomic, retain, readonly) NSDictionary *idToNodeKey;

@end

@protocol EucCSSIntermediateDocumentDataProvider

- (NSData *)dataForURL:(NSURL *)url;

@end