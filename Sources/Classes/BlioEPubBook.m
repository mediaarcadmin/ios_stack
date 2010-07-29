//
//  BlioEPubBook.m
//  BlioApp
//
//  Created by James Montgomerie on 06/07/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioBook.h"
#import "BlioEPubBook.h"
#import "BlioBookManager.h"

@implementation BlioEPubBook

@synthesize blioBookID;

- (id)initWithBookID:(NSManagedObjectID *)aBookID
{
    BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:aBookID];
    if([book hasEPub]) {
        NSString *ePubPath = book.ePubPath;
        if ((self = [super initWithPath:ePubPath])) {
            self.blioBookID = aBookID;
            self.persistsPositionAutomatically = NO;
        }
    } else {
        [self release];
        self = nil;
    }
    return self;
}


- (void)dealloc
{
    self.blioBookID = nil;
    
    [super dealloc];
}

@end
