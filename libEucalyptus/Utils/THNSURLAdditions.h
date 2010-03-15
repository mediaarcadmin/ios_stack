//
//  THNSURLAdditions.h
//  libEucalyptus
//
//  Created by James Montgomerie on 14/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (THAdditions)

- (NSString *)pathRelativeTo:(NSURL *)baseUrl;

@end
