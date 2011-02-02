//
//  EucBUpeZipDataProvider.h
//  libEucalyptus
//
//  Created by James Montgomerie on 02/02/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucBUpeDataProvider.h"

@interface EucBUpeZipDataProvider :  NSObject <EucBUpeDataProvider> {
    void *_unzfile;
}

- (id)initWithZipFileAtPath:(NSString *)path;

@end
