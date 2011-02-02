//
//  EucBUpeDataProvider.h
//  libEucalyptus
//
//  Created by James Montgomerie on 02/02/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EucBUpeDataProvider <NSObject>

- (NSData *)dataForComponentAtPath:(NSString *)path;

@end
