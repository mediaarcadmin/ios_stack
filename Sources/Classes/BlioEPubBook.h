//
//  BlioEPubBook.h
//  BlioApp
//
//  Created by James Montgomerie on 06/07/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <libEucalyptus/EucBUpeBook.h>

#import "BlioBUpeBook.h"

@interface BlioEPubBook : EucBUpeBook <BlioBUpeBook> {}

@property (nonatomic, retain) NSManagedObjectID *blioBookID;

- (id)initWithBookID:(NSManagedObjectID *)aBookID;

@end
