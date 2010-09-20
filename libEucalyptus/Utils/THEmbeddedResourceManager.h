//
//  THEmbeddedResourceManager.h
//  libEucalyptus
//
//  Created by James Montgomerie on 14/09/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface THEmbeddedResourceManager : NSObject {}

+ (NSData *)embeddedResourceWithName:(NSString *)name;

@end
