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

- (BlioBookmarkPoint *)bookmarkPointFromBookPageIndexPoint:(EucBookPageIndexPoint *)indexPoint
{
    if(!indexPoint) {
        return nil;   
    } else {
        EucBookPageIndexPoint *eucIndexPoint = [indexPoint copy];
        
        // EucIndexPoint words start with word 0 == before the first word,
        // but Blio thinks that the first word is at 0.  This is a bit lossy,
        // but there's not much else we can do.
        if(eucIndexPoint.word == 0) {
            eucIndexPoint.element = 0;
        } else {
            eucIndexPoint.word -= 1;
        }    
        
        BlioBookmarkPoint *ret = [[BlioBookmarkPoint alloc] init];
        ret.layoutPage = eucIndexPoint.source + 1;
        ret.blockOffset = eucIndexPoint.block;
        ret.wordOffset = eucIndexPoint.word;
        ret.elementOffset = eucIndexPoint.element;
        
        [eucIndexPoint release];
        
        return [ret autorelease];    
    }
}

- (EucBookPageIndexPoint *)bookPageIndexPointFromBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    if(!bookmarkPoint) {
        return nil;   
    } else {
        EucBookPageIndexPoint *eucIndexPoint = [[EucBookPageIndexPoint alloc] init];
        
        eucIndexPoint.source = bookmarkPoint.layoutPage - 1;
        eucIndexPoint.block = bookmarkPoint.blockOffset;
        eucIndexPoint.word = bookmarkPoint.wordOffset;
        eucIndexPoint.element = bookmarkPoint.elementOffset;
        
        // EucIndexPoint words start with word 0 == before the first word,
        // but Blio thinks that the first word is at 0.  This is a bit lossy,
        // but there's not much else we can do.    
        eucIndexPoint.word += 1;
        
        return [eucIndexPoint autorelease];  
    }    
}

@end
