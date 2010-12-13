//
//  THNSDataAdditions.h
//  Eucalyptus
//
//  Created by James Montgomerie on 03/11/2009.
//  Copyright 2009 James Montgomerie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface  NSData (THNSDataAdditions)

- (BOOL)writeToMappedFile:(NSString *)path;

@end
