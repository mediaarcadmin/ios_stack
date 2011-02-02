//
//  EucBUpeFilesystemDataProvider.m
//  libEucalyptus
//
//  Created by James Montgomerie on 02/02/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import "EucBUpeFilesystemDataProvider.h"

@implementation EucBUpeFilesystemDataProvider

- (id)initWithBasePath:(NSString *)basePath
{
    if((self = [super init])) {
        _basePath = [basePath copy];
    }
    return self;
}

- (void)dealloc
{
    [_basePath release];
    
    [super dealloc];
}

- (NSData *)dataForComponentAtPath:(NSString *)path
{
    return [NSData dataWithContentsOfMappedFile:[_basePath stringByAppendingPathComponent:path]];
}

@end
