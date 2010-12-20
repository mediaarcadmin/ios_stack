/*
 *  EucCSSIntermediateDocument_Package.h
 *  libEucalyptus
 *
 *  Created by James Montgomerie on 14/03/2010.
 *  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
 *
 */

#import <libwapcaplet/libwapcaplet.h>
#import <libcss/libcss.h>

#define EUC_CSS_INTERMEDIATE_DOCUMENT_NODE_KEY_FLAG_MASK ((uint32_t)0x7)
#define EUC_CSS_DOCUMENT_TREE_NODE_TO_INTERMEDIATE_DOCUMENT_NODE_KEY_SHIFT_FOR_FLAGS 3

@interface EucCSSIntermediateDocument ()

css_error EucResolveURL(void *pw, lwc_context *dict, const char *base, lwc_string *rel, lwc_string **abs);

- (id)initWithDocumentTree:(id<EucCSSDocumentTree>)documentTree
              baseCSSPaths:(NSArray *)baseCSSPaths
              userCSSPaths:(NSArray *)userCSSPaths
                    forURL:(NSURL *)url
                dataSource:(id<EucCSSIntermediateDocumentDataSource>)dataSource
                    isHTML:(BOOL)isHTML
                lwcContext:(lwc_context *)lwcContext;

@property (nonatomic, readonly) css_select_ctx *selectContext;
@property (nonatomic, readonly) lwc_context *lwcContext;

@end