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

@class EucHTMLDBNodeManager;

@interface EucHTMLDBNode : NSObject {
    EucHTMLDBNodeManager *_manager;
    EucHTMLDB *_htmlDb;
    uint32_t _key;
    
    lwc_context *_lwcContext;
    
    uint32_t *_rawNode;
    lwc_string *_name;
    
    uint32_t *_attributeArray;
    uint32_t _attributeArrayCount;
    
    uint32_t *_childrenKeys;
    uint32_t _childrenKeysCount;
    
    lwc_string **_classes;
    uint32_t _classesCount;
    
    char *_characterContents;
    size_t _characterContentsLength;
} 

+ (css_select_handler *)selectHandler;
- (id)initWithManager:(EucHTMLDBNodeManager *)manager
               HTMLDB:(EucHTMLDB *)htmlDb 
                  key:(uint32_t)key 
           lwcContext:(lwc_context *)lwcContext;

@property (nonatomic, readonly) uint32_t kind;
@property (nonatomic, readonly) uint32_t key;

@property (nonatomic, readonly) lwc_context *lwcContext;
@property (nonatomic, readonly) lwc_string *name;
@property (nonatomic, readonly) uint32_t *attributeArray;
@property (nonatomic, readonly) uint32_t attributeArrayCount;
@property (nonatomic, readonly) uint32_t *childrenKeys;
@property (nonatomic, readonly) uint32_t childrenKeysCount;
@property (nonatomic, readonly) lwc_string **classes;
@property (nonatomic, readonly) uint32_t classesCount;

@property (nonatomic, readonly) EucHTMLDBNode *nextNode;
@property (nonatomic, readonly) EucHTMLDBNode *parentNode;
- (EucHTMLDBNode *)nextNodeUnder:(EucHTMLDBNode *)node;
- (EucHTMLDBNode *)nextNodeWithName:(lwc_string *)name;
- (EucHTMLDBNode *)firstChild;

- (BOOL)getCharacterContents:(char **)contents length:(size_t *)length;

- (hubbub_string)copyHubbubAttributeForName:(const char *)name;
- (lwc_string *)copyLwcStringAttributeForName:(const char *)name;
- (EucHTMLDBNode *)closestAncestorWithName:(lwc_string *)name;
- (EucHTMLDBNode *)parentWithName:(lwc_string *)name;
- (EucHTMLDBNode *)adjacentSiblingWithName:(lwc_string *)name;

@end