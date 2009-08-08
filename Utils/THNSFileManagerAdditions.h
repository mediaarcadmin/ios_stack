//
//  THNSFileManagerAdditions.h
//  Eucalyptus
//
//  Created by James Montgomerie on 27/11/2008.
//  Copyright 2008 James Montgomerie. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSFileManager (THAdditions)

- (NSString *)stringExtendedAttributeWithName:(NSString *)name ofItemAtPath:(NSString *)path;
- (BOOL)setStringExtendedAttributeWithName:(NSString *)name ofItemAtPath:(NSString *)path to:(NSString *)value;


- (uint64_t)uint64ExtendedAttributeWithName:(NSString *)name ofItemAtPath:(NSString *)path;
- (BOOL)setUint64ExtendedAttributeWithName:(NSString *)name ofItemAtPath:(NSString *)path to:(uint64_t)value;

@end
