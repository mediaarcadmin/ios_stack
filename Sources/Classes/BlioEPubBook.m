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

#import <libEucalyptus/EucBUpeDataProvider.h>
#import <libEucalyptus/EucBUpeFilesystemDataProvider.h>
#import <libEucalyptus/EucBUpeZipDataProvider.h>

@implementation BlioEPubBook

@synthesize blioBookID;

- (id)initWithBookID:(NSManagedObjectID *)aBookID
{
    BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:aBookID];
    id<EucBUpeDataProvider> dataProvider = nil;
    if([book hasEPub]) {
        NSString *ePubPath = book.ePubPath;
        BOOL directory = YES;
        if([[NSFileManager defaultManager] fileExistsAtPath:ePubPath isDirectory:&directory]) {
            if(directory) {
                // This is an ePub imported by v2.1, which unzipped the package
                // into the filesystem after download.
                dataProvider = [[EucBUpeFilesystemDataProvider alloc] initWithBasePath:ePubPath];
            } else {
                dataProvider = [[EucBUpeZipDataProvider alloc] initWithZipFileAtPath:ePubPath];
            }
        }
    }
    if(dataProvider) {
        if ((self = [super initWithDataProvider:dataProvider cacheDirectoryPath:[book.bookCacheDirectory stringByAppendingPathComponent:BlioBookEucalyptusCacheDir]])) {
            self.blioBookID = aBookID;
            self.persistsPositionAutomatically = NO;
        }
        [dataProvider release];
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
