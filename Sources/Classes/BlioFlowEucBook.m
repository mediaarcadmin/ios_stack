//
//  BlioFlowEucBook.m
//  BlioApp
//
//  Created by James Montgomerie on 19/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioFlowEucBook.h"
#import "BlioBook.h"
#import "BlioBookManager.h"
#import "BlioTextFlow.h"
#import "BlioTextFlowFlowTree.h"
#import "BlioTextFlowXAMLTree.h"
#import "BlioXPSProvider.h"
#import "BlioParagraphSource.h"

#import <libEucalyptus/EucBookPageIndexPoint.h>
#import <libEucalyptus/EucBookNavPoint.h>
#import <libEucalyptus/EucCSSXHTMLTree.h>
#import <libEucalyptus/THPair.h>
#import <libEucalyptus/THRegex.h>

#import <CoreData/CoreData.h>

@implementation BlioFlowEucBook

#pragma mark -
#pragma mark Overriden methods

- (id)initWithBookID:(NSManagedObjectID *)blioBookID
{

    BlioBookManager *bookManager = [BlioBookManager sharedBookManager];
    BlioBook *blioBook = [bookManager bookWithID:blioBookID];
    if(blioBook && (self = [super initWithBookID:blioBookID])) {
        self.textFlow = [bookManager checkOutTextFlowForBookWithID:blioBookID];
        self.fakeCover = self.textFlow.flowTreeKind == BlioTextFlowFlowTreeKindFlow && [blioBook hasManifestValueForKey:BlioManifestCoverKey];
        
        self.title = blioBook.title;
        self.author = blioBook.author;
        self.etextNumber = nil;
        
        self.cacheDirectoryPath = [blioBook.bookCacheDirectory stringByAppendingPathComponent:BlioBookEucalyptusCacheDir];
    }
    
    return self;
}

- (void)dealloc
{
    [[BlioBookManager sharedBookManager] checkInTextFlowForBookWithID:self.bookID];
    
    BlioBook *aBook = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
    [aBook flushCaches];
    
    [super dealloc];
}

- (NSData *)dataForURL:(NSURL *)url
{
    if([[url absoluteString] isEqualToString:@"textflow:coverimage"]) {
        return [[[BlioBookManager sharedBookManager] bookWithID:self.bookID] manifestDataForKey:BlioManifestCoverKey];
    } else if([[url scheme] isEqualToString:@"textflow"]) {
		NSString *componentPath = [[url absoluteURL] path];
		NSString *relativePath = [url relativeString];		
		if ([relativePath length] && ([relativePath characterAtIndex:0] != '/')) {
			componentPath = [BlioXPSEncryptedTextFlowDir stringByAppendingPathComponent:relativePath];
		}
		
        BlioXPSProvider *provider = [[BlioBookManager sharedBookManager] checkOutXPSProviderForBookWithID:self.bookID];
        NSData *ret = [provider dataForComponentAtPath:componentPath];
        [[BlioBookManager sharedBookManager] checkInXPSProviderForBookWithID:self.bookID];
        return ret;
    }
    return [super dataForURL:url];
}

-(EucBookPageIndexPoint *)indexPointForPage:(NSUInteger)page 
{
    BlioBookmarkPoint *point = [[[BlioBookmarkPoint alloc] init] autorelease];
    point.layoutPage = page;
    return [self bookPageIndexPointFromBookmarkPoint:point];
}
    
#pragma mark -
#pragma mark BlioBUpeBook methods

- (BlioBookmarkPoint *)bookmarkPointFromBookPageIndexPoint:(EucBookPageIndexPoint *)indexPoint
{
    BlioBookmarkPoint *ret = nil;
    
    EucBookPageIndexPoint *eucIndexPoint = [indexPoint copy];
    
    // EucIndexPoint words start with word 0 == before the first word,
    // but Blio thinks that the first word is at 0.  This is a bit lossy,
    // but there's not much else we can do.
    if(eucIndexPoint.word == 0) {
        eucIndexPoint.element = 0;
    } else {
        eucIndexPoint.word -= 1;
    }
    
    if(eucIndexPoint.source == 0 && self.fakeCover) {
        ret = [[BlioBookmarkPoint alloc] init];
        // This is the cover section.
        ret.layoutPage = 1;
        ret.blockOffset = 0;
        ret.wordOffset = 0;
        ret.elementOffset = 0;
    } else if(self.fakeCover) {
        eucIndexPoint.source--;
    }
    
    if(!ret) {
        ret = [[BlioBookmarkPoint alloc] init];
        
        NSUInteger indexes[2] = { eucIndexPoint.source , [EucCSSIntermediateDocument documentTreeNodeKeyForKey:eucIndexPoint.block]};
        NSIndexPath *indexPath = [[NSIndexPath alloc] initWithIndexes:indexes length:2];
        
        BlioBookManager *bookManager = [BlioBookManager sharedBookManager];
        id<BlioParagraphSource> paragraphSource = [bookManager checkOutParagraphSourceForBookWithID:bookID];
        BlioBookmarkPoint *bookmarkPoint = [paragraphSource bookmarkPointFromParagraphID:indexPath wordOffset:eucIndexPoint.word];
        [bookManager checkInParagraphSourceForBookWithID:bookID];
        
        [indexPath release];
        
        if(bookmarkPoint) {
            ret.layoutPage = bookmarkPoint.layoutPage;
            ret.blockOffset = bookmarkPoint.blockOffset;
            ret.wordOffset = bookmarkPoint.wordOffset;
            ret.elementOffset = eucIndexPoint.element;
        }
    }

    [eucIndexPoint release];
    
    return [ret autorelease];    
}

- (EucBookPageIndexPoint *)bookPageIndexPointFromBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    if(!bookmarkPoint) {
        return nil;   
    } else {
        EucBookPageIndexPoint *eucIndexPoint = [[EucBookPageIndexPoint alloc] init];
        
        NSIndexPath *paragraphID = nil;
        uint32_t wordOffset = 0;
            
        BlioBookManager *bookManager = [BlioBookManager sharedBookManager];
        id<BlioParagraphSource> paragraphSource = [bookManager checkOutParagraphSourceForBookWithID:bookID];
        [paragraphSource bookmarkPoint:bookmarkPoint
                         toParagraphID:&paragraphID 
                            wordOffset:&wordOffset];
        [bookManager checkInParagraphSourceForBookWithID:bookID];

        eucIndexPoint.source = [paragraphID indexAtPosition:0];
        eucIndexPoint.block = [EucCSSIntermediateDocument keyForDocumentTreeNodeKey:[paragraphID indexAtPosition:1]];
        eucIndexPoint.word = wordOffset;
        eucIndexPoint.element = bookmarkPoint.elementOffset;

        if(self.fakeCover) {
            eucIndexPoint.source++;
        }        
        
        // EucIndexPoint words start with word 0 == before the first word,
        // but Blio thinks that the first word is at 0.  This is a bit lossy,
        // but there's not much else we can do.    
        eucIndexPoint.word += 1;
        
        return [eucIndexPoint autorelease];  
    }
}

@end
