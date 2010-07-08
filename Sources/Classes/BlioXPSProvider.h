//
//  BlioXPSProvider.h
//  BlioApp
//
//  Created by matt on 08/07/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface BlioXPSProvider : NSObject {
    NSManagedObjectID *bookID;
}

@property (nonatomic, retain) NSManagedObjectID *bookID;

- (id)initWithBookID:(NSManagedObjectID *)aBookID;

@end
