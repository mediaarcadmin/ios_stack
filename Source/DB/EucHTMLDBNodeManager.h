//
//  EucHTMLNodeManager.h
//  LibCSSTest
//
//  Created by James Montgomerie on 08/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libwapcaplet/libwapcaplet.h>
#import "EucHTMLDB.h"

@class EucHTMLDBNode;

@interface EucHTMLDBNodeManager : NSObject {
    EucHTMLDB *_htmlDb;
    lwc_context *_lwcContext;
    CFMutableDictionaryRef _keyToExtantNode;
    
    uint32_t _htmlRootKey;
}

- (id)initWithHTMLDB:(EucHTMLDB *)htmlDb lwcContext:(lwc_context *)lwcContext;
- (EucHTMLDBNode *)nodeForKey:(uint32_t)key;

@property (nonatomic, retain, readonly) EucHTMLDBNode *rootNode;

// Private - used by EucHTMLDBNode.
@property (nonatomic, assign, readonly) uint32_t htmlRootKey;
- (void)notifyOfDealloc:(EucHTMLDBNode *)node;

@end
