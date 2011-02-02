//
//  BlioEPubXPSDataProvider.h
//  BlioApp
//
//  Created by James Montgomerie on 02/02/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <libEucalyptus/EucBUpeDataProvider.h>

@class BlioXPSProvider;

@interface BlioEPubXPSDataProvider : NSObject <EucBUpeDataProvider> {
    NSManagedObjectID *bookID;
    BlioXPSProvider *xpsProvider;
    
    NSString *ePubRootInXPS;
}

- (id)initWithWithBookID:(NSManagedObjectID *)aBookID;

@end
