//
//  BlioXPSProvider.h
//  BlioApp
//
//  Created by matt on 08/07/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BlioLayoutDataSource.h"
#import "XpsSdk.h"

@interface BlioXPSProvider : NSObject <BlioLayoutDataSource> {
    NSManagedObjectID *bookID;
    
    NSLock *renderingLock;
    NSLock *contentsLock;
    NSLock *inflateLock;
    
    NSString *tempDirectory;
    NSInteger pageCount;
    RasterImageInfo *imageInfo;
    XPS_HANDLE xpsHandle;
    FixedPageProperties properties;
    
    NSMutableDictionary *xpsData;
}

@property (nonatomic, retain) NSManagedObjectID *bookID;

- (id)initWithBookID:(NSManagedObjectID *)aBookID;
- (NSData *)dataForComponentAtPath:(NSString *)path;

@end
