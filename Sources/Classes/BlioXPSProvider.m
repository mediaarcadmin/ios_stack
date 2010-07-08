//
//  BlioXPSProvider.m
//  BlioApp
//
//  Created by matt on 08/07/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioXPSProvider.h"
#import "BlioBook.h"
#import "BlioBookManager.h"

@interface BlioXPSProvider()

@property (nonatomic, assign, readonly) BlioBook *book;

@end

@implementation BlioXPSProvider

@synthesize bookID;

- (void)dealloc {
    [[BlioBookManager sharedBookManager] xpsProviderIsDeallocingForBookWithID:self.bookID];
    
    self.bookID = nil;
    
    [super dealloc];
}

- (id)initWithBookID:(NSManagedObjectID *)aBookID {
    if ((self = [super init])) {
        self.bookID = aBookID;
    }
    return self;
} 

- (BlioBook *)book {
    return [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
}

@end
