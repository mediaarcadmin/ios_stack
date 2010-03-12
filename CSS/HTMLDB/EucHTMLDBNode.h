/*
 *  EucHTMLDBNode.h
 *  LibCSSTest
 *
 *  Created by James Montgomerie on 06/12/2009.
 *  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
 *
 */

#import "EucHTMLDB.h"
#import <libwapcaplet/libwapcaplet.h>
#import <libcss/libcss.h>

#import "EucCSSDocumentTreeNode.h"

@class EucHTMLDBNodeManager;

@interface EucHTMLDBNode : NSObject <EucCSSDocumentTreeNode> {
    EucHTMLDBNodeManager *_manager;
    EucHTMLDB *_htmlDb;
    uint32_t _key;
    
    lwc_context *_lwcContext;
    
    uint32_t *_rawNode;
    NSString *_name;
    
    uint32_t *_attributeArray;
    uint32_t _attributeArrayCount;
    
    uint32_t *_childKeys;
    uint32_t _childCount;
    
    lwc_string **_classes;
    uint32_t _classesCount;
    
    char *_characterContents;
    size_t _characterContentsLength;
} 

- (id)initWithManager:(EucHTMLDBNodeManager *)manager
               HTMLDB:(EucHTMLDB *)htmlDb 
                  key:(uint32_t)key 
           lwcContext:(lwc_context *)lwcContext;

@property (nonatomic, assign, readonly) lwc_context *lwcContext;

@end