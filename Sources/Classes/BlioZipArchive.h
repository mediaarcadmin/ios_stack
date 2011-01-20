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

@end
