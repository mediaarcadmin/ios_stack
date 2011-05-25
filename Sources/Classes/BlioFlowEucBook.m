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
#import <libEucalyptus/EucCSSLayoutRunExtractor.h>
#import <libEucalyptus/THPair.h>
#import <libEucalyptus/THRegex.h>

#import <CoreData/CoreData.h>
#import <objc/runtime.h>

static NSString const *BlioFlowEucBookConvertedPointKey = @"BlioFlowEucBookConvertedPointKey";

@implementation BlioFlowEucBook

#pragma mark -
#pragma mark Overriden methods

- (id)initWithBookID:(NSManagedObjectID *)blioBookID
{

    BlioBookManager *bookManager = [BlioBookManager sharedBookManager];
    BlioBook *blioBook = [bookManager bookWithID:blioBookID];
    if(blioBook) {
        BlioTextFlow *aTextFlow = [bookManager checkOutTextFlowForBookWithID:blioBookID];
        BOOL aFakeCover = aTextFlow.flowTreeKind == BlioTextFlowFlowTreeKindFlow && [blioBook hasManifestValueForKey:BlioManifestCoverKey];
        NSString *aCacheDirectoryPath = [blioBook.bookCacheDirectory stringByAppendingPathComponent:BlioBookEucalyptusCacheDir];
        
        if ((self = [super initWithBookID:blioBookID
                       cacheDirectoryPath:aCacheDirectoryPath
                                 textFlow:aTextFlow
                                fakeCover:aFakeCover])) 
        {
            self.title = blioBook.title;
            self.author = blioBook.author;
            self.etextNumber = nil;
        }
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

-(EucBookPageIndexPoint *)indexPointForLayoutPage:(NSUInteger)page 
{
    BlioBookmarkPoint *point = [[[BlioBookmarkPoint alloc] init] autorelease];
    point.layoutPage = page;
    return [self bookPageIndexPointFromBookmarkPoint:point];
}
    
#pragma mark -
#pragma mark BlioBUpeBook methods

- (BlioBookmarkPoint *)bookmarkPointFromBookPageIndexPoint:(EucBookPageIndexPoint *)eucIndexPoint
{
    if(!eucIndexPoint) {
        return nil;   
    } else {
        // Do we have an associated bookmark point from an earlier conversion?
        BlioBookmarkPoint *bookmarkPoint = objc_getAssociatedObject(eucIndexPoint, BlioFlowEucBookConvertedPointKey);
           
        if(!bookmarkPoint) {
            if(eucIndexPoint.source == 0 && self.fakeCover) {
                bookmarkPoint = [[BlioBookmarkPoint alloc] init];
                // This is the cover section.
                bookmarkPoint.layoutPage = 1;
                bookmarkPoint.blockOffset = 0;
                bookmarkPoint.wordOffset = 0;
                bookmarkPoint.elementOffset = 0;
            } else {
                bookmarkPoint = [[[BlioBookmarkPoint alloc] init] autorelease];
                
                NSUInteger indexes[2];
                if (self.fakeCover) {
                    indexes[0] = eucIndexPoint.source - 1;
                } else {
                    indexes[0] = eucIndexPoint.source;
                }
                
                // Make sure that the 'block' in our index point actually corresponds to a block-level node (i.e. a paragraph)
                // in the XML, so that our constructd bookmark point is valid.
                // We do this by using the layout engine to map the index point to its canonical layout point, which always
                // refers to a valid block ID.
                EucCSSLayoutRunExtractor *extractor = [[EucCSSLayoutRunExtractor alloc] initWithDocument:[self intermediateDocumentForIndexPoint:eucIndexPoint]];
                EucCSSLayoutPoint layoutPoint = [extractor layoutPointForNode:[extractor.document nodeForKey:eucIndexPoint.block]];
                
                indexes[1] = [EucCSSIntermediateDocument documentTreeNodeKeyForKey:layoutPoint.nodeKey];
                
                NSIndexPath *indexPath = [[NSIndexPath alloc] initWithIndexes:indexes length:2];
                
                // EucIndexPoint words start with word 0 == before the first word,
                uint32_t schWordOffset;
                uint32_t schElementOffset;
                if (layoutPoint.nodeKey == eucIndexPoint.block) {
                    // The layout mapping, above, didn't change anything, so the 
                    // word and element offset is valid.
                    
                    // EucIndexPoint words start with word 0 == before the first word,
                    // Blio starts at word 0 == the first word.
                    schWordOffset =  eucIndexPoint.word > 0 ? eucIndexPoint.word - 1 : 0;
                    schElementOffset = eucIndexPoint.word> 0 ? eucIndexPoint.element : 0;
                } else {
                    // This mapping will be a little lossy - the original word and element offsets are
                    // no longer valid, and we don't know what they should be.
                    
                    // EucIndexPoint words start with word 0 == before the first word,
                    // Blio starts at word 0 == the first word.
                    schWordOffset =  layoutPoint.word > 0 ? layoutPoint.word - 1 : 0;
                    schElementOffset =  layoutPoint.word > 0 ? layoutPoint.element : 0;
                }
                
                BlioBookManager *bookManager = [BlioBookManager sharedBookManager];
                id<BlioParagraphSource> paragraphSource = [bookManager checkOutParagraphSourceForBookWithID:bookID];
                BlioBookmarkPoint *bookPoint = [paragraphSource bookmarkPointFromParagraphID:indexPath wordOffset:schWordOffset];
                [bookManager checkInParagraphSourceForBookWithID:bookID];

                [indexPath release];        
                
                if (bookPoint) {
                    // The layout mapping, above, didn't change anything, so the 
                    // word and element offset is valid.
                    bookmarkPoint.layoutPage = bookPoint.layoutPage;
                    bookmarkPoint.blockOffset = bookPoint.blockOffset;
                    bookmarkPoint.wordOffset = bookPoint.wordOffset;
                    bookmarkPoint.elementOffset = schElementOffset;
                }
            }
            
            if(bookmarkPoint) {
                // Store this conversion for easy lookup later in either direction.
                objc_setAssociatedObject(eucIndexPoint, BlioFlowEucBookConvertedPointKey, bookmarkPoint, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                EucBookPageIndexPoint *eucIndexPointCopy = [eucIndexPoint copy]; // Copy to avoid a retain cycle.
                objc_setAssociatedObject(bookmarkPoint, BlioFlowEucBookConvertedPointKey, eucIndexPointCopy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [eucIndexPointCopy release];
            }
        }
        return bookmarkPoint;
    }
}

- (EucBookPageIndexPoint *)bookPageIndexPointFromBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    if(!bookmarkPoint) {
        return nil;   
    } else {
        // Do we have an associated index point from an earlier conversion?
        EucBookPageIndexPoint *eucIndexPoint = objc_getAssociatedObject(bookmarkPoint, BlioFlowEucBookConvertedPointKey);

        if(!eucIndexPoint) {
            eucIndexPoint =  [[[EucBookPageIndexPoint alloc] init] autorelease];
            if(bookmarkPoint.layoutPage <= 1 &&
               bookmarkPoint.blockOffset == 0 &&
               bookmarkPoint.wordOffset == 0 &&
               bookmarkPoint.elementOffset == 0) {
                // Do nothing - this is the front of the book, so we want an all-zero index point.
            } else {
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
            }
            
            if(eucIndexPoint) {
                // Store this conversion for easy lookup later in either direction.
                objc_setAssociatedObject(eucIndexPoint, BlioFlowEucBookConvertedPointKey, bookmarkPoint, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                EucBookPageIndexPoint *eucIndexPointCopy = [eucIndexPoint copy]; // Copy to avoid a retain cycle.
                objc_setAssociatedObject(bookmarkPoint, BlioFlowEucBookConvertedPointKey, eucIndexPointCopy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [eucIndexPointCopy release];
            }
        }
        return eucIndexPoint;  
    }
}

@end
