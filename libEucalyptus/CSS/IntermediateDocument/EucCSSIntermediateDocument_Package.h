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

@interface EucCSSIntermediateDocument ()

CGFloat EucCSSLibCSSSizeToPixels(css_computed_style *computed_style, css_fixed size, css_unit units, CGFloat percentageBase);
css_error EucResolveURL(void *pw, lwc_context *dict, const char *base, lwc_string *rel, lwc_string **abs);

- (id)initWithDocumentTree:(id<EucCSSDocumentTree>)documentTree 
               baseCSSPath:(NSString *)baseCSSPath
                lwcContext:(lwc_context *)lwcContext;

@property (nonatomic, readonly) id<EucCSSDocumentTree> documentTree;
@property (nonatomic, readonly) css_select_ctx *selectContext;
@property (nonatomic, readonly) lwc_context *lwcContext;

// Private - used by EucHTMLDBNode.
- (void)notifyOfDealloc:(EucCSSIntermediateDocumentNode *)node;

@end