//
//  BlioZipArchive.m
//  BlioApp
//
//  Created by Matt Farrugia on 20/01/2011.
//  Copyright 2011 BitWink. All rights reserved.
//

#import "BlioZipArchive.h"


@implementation BlioZipArchive

/*
 * Uses the following byte offsets taken from http://en.wikipedia.org/wiki/ZIP_(file_format)
 *
 *   Offset Bytes	Description
 *    0		4		Central directory file header signature = 0x02014b50
 *   4		2		Version made by
 *   6		2		Version needed to extract (minimum)
 *   8		2		General purpose bit flag
 *  10		2		Compression method
 *  12		2		File last modification time
 *  14		2		File last modification date
 *  16		4		CRC-32
 *  20		4		Compressed size
 *  24		4		Uncompressed size
 *  28		2		File name length (n)
 *  30		2		Extra field length (m)
 *  32		2		File comment length (k)
 *  34		2		Disk number where file starts
 *  36		2		Internal file attributes
 *  38		4		External file attributes
 *  42		4		Relative offset of local file header
 *  46		n		File name
 *  46+n	m		Extra field
 *  46+n+m	k		File comment
 *
 */

+ (NSArray *)contentsOfCentralDirectory:(void *)directoryPtr numberOfEntries:(NSUInteger)entries {
		
	size_t filenameLengthOffset    = 28;
	size_t extraFieldLengthOffset  = 30;
	size_t fileCommentLengthOffset = 32;
	size_t filenameOffset		   = 46;
	
	NSMutableArray *contents = [NSMutableArray array];
	
	for (int i=0; i < entries; i++) {
		
		void *filenameSizePtr    = directoryPtr + filenameLengthOffset;		
		void *extraFieldSizePtr  = directoryPtr + extraFieldLengthOffset;
		void *fileCommentSizePtr = directoryPtr + fileCommentLengthOffset;
		
		UInt16 filenameLength    = CFSwapInt16LittleToHost(*(UInt16 *)filenameSizePtr);
		UInt16 extraFieldLength  = CFSwapInt16LittleToHost(*(UInt16 *)extraFieldSizePtr);
		UInt16 fileCommentLength = CFSwapInt16LittleToHost(*(UInt16 *)fileCommentSizePtr);
		
		void *filenamePtr = directoryPtr + filenameOffset;
		
		char filename[1024];
		filename[0] = '\0';
		
		if (filenameLength < 1024) {
			memcpy(filename, filenamePtr, filenameLength);
			filename[filenameLength] = '\0';
			NSString *path = [NSString stringWithFormat:@"/%@", [NSString stringWithCString:filename encoding:NSUTF8StringEncoding]];
			if (path) {
				[contents addObject:path];
			}
		} else {
			NSLog(@"Filename too long: %d", filenameLength);
		}
		
		directoryPtr = filenamePtr + filenameLength + extraFieldLength + fileCommentLength;
	}
	
	return contents;
	
}

@end
