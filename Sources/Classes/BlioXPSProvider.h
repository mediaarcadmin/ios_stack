//
//  BlioXPSProvider.h
//  BlioApp
//
//  Created by matt on 08/07/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "KNFBXPSProvider.h"
#import "BlioLayoutDataSource.h"

@class BlioDrmSessionManager;

@interface BlioXPSProvider : KNFBXPSProvider <BlioLayoutDataSource> {
    NSManagedObjectID *bookID;
	BlioDrmSessionManager* drmSessionManager;
    NSSet *enhancedContentItems;
}

- (id)initWithBookID:(NSManagedObjectID *)aBookID;

@property (nonatomic, retain, readonly) NSManagedObjectID *bookID;

@end
