//
//  BlioZipArchive.h
//  BlioApp
//
//  Created by Matt Farrugia on 20/01/2011.
//  Copyright 2011 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BlioZipArchive : NSObject {

}

+ (NSArray *)contentsOfCentralDirectory:(void *)directoryPtr numberOfEntries:(NSUInteger)entries;
+ (NSUInteger)headerOffsetOfFile:(NSString *)targetFile inCentralDirectory:(void *)directoryPtr numberOfEntries:(NSUInteger)entries;
+ (NSUInteger)lengthOfFileHeader:(const void *)headerPtr compressedSize:(unsigned long long *)compressed uncompressedSize:(unsigned long long *)uncompressed;

@end
