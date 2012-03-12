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

#import <libEucalyptus/EucEPubDataProvider.h>
#import <libEucalyptus/EucEPubBookReference.h>
#import <libEucalyptus/EucEPubFilesystemDataProvider.h>
#import <libEucalyptus/EucEPubZipDataProvider.h>

#import "BlioEPubXPSDataProvider.h"

@implementation BlioEPubBook

@synthesize blioBookID;

- (id)initWithBookID:(NSManagedObjectID *)aBookID
{
    BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:aBookID];
    id<EucEPubDataProvider> dataProvider = nil;
    if([book hasEPub]) {
        if([[book manifestLocationForKey:BlioManifestEPubKey] isEqual:BlioManifestEntryLocationXPS]) {
            dataProvider = [[BlioEPubXPSDataProvider alloc] initWithWithBookID:aBookID];
        } else {
            NSString *ePubPath = book.ePubPath;
            if(ePubPath) {
                BOOL directory = YES;
                if([[NSFileManager defaultManager] fileExistsAtPath:ePubPath isDirectory:&directory]) {
                    if(directory) {
                        // This is an ePub imported by v2.1, which unzipped the package
                        // into the filesystem after download.
                        dataProvider = [[EucEPubFilesystemDataProvider alloc] initWithBasePath:ePubPath];
                    } else {
                        dataProvider = [[EucEPubZipDataProvider alloc] initWithZipFileAtPath:ePubPath];
                    }
                }
            } 
        }
    }
    if(dataProvider) {
        EucEPubBookReference *bookReference = [[EucEPubBookReference alloc] initWithDataProvider:dataProvider];
        if(bookReference) {
            if ((self = [super initWithBookReference:bookReference 
                                 cacheDirectoryPath:[book.bookCacheDirectory stringByAppendingPathComponent:BlioBookEucalyptusCacheDir]])) {
                self.blioBookID = aBookID;
            }
            [bookReference release];
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

- (NSArray *)userAgentCSSDatasForDocumentTree:(id<EucCSSDocumentTree>)documentTree
{
    NSMutableArray *ret = [[[super userAgentCSSDatasForDocumentTree:documentTree] mutableCopy] autorelease];
    [ret addObject:[NSData dataWithContentsOfMappedFile:[[NSBundle mainBundle] pathForResource:@"ePubBaseOverrides" ofType:@"css"]]];
    return ret;
}

- (NSArray *)userCSSDatasForDocumentTree:(id<EucCSSDocumentTree>)documentTree
{
    NSMutableArray *ret = [[[super userAgentCSSDatasForDocumentTree:documentTree] mutableCopy] autorelease];
    
    NSMutableString *cssString = [NSMutableString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"BlioEPUB3Overrides" ofType:@"css"] 
                                                                  encoding:NSUTF8StringEncoding error:NULL];
    [cssString replaceOccurrencesOfString:@"%VIDEOPLACEHOLDERTEXT%" 
                               withString:NSLocalizedString(@"Sorry, this version of Blio cannot play embedded videos.", @"Placeholder text for EPUB3 video content") 
                                  options:0 
                            range:NSMakeRange(0, cssString.length)];
    [cssString replaceOccurrencesOfString:@"%AUDIOPLACEHOLDERTEXT%" 
                               withString:NSLocalizedString(@"Sorry, this version of Blio cannot play embedded audio.", @"Placeholder text for EPUB3 audio content") 
                                  options:0 
                                    range:NSMakeRange(0, cssString.length)];

    [ret addObject:[cssString dataUsingEncoding:NSUTF8StringEncoding]];
    return ret;
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
