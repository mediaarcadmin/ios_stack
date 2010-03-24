//
//  BlioTextFlowFlowTree.h
//  BlioApp
//
//  Created by James Montgomerie on 18/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libEucalyptus/EucCSSDocumentTree.h>

@class BlioTextFlow;

@interface BlioTextFlowFlowTree : NSObject <EucCSSDocumentTree> {
    NSArray *_nodes;
}

- (id)initWithTextFlow:(BlioTextFlow *)textFlow data:(NSData *)xmlData;

@end
