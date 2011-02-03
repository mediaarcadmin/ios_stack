//
//  EucBUpeBook.h
//  libEucalyptus
//
//  Created by James Montgomerie on 12/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "THCache.h"
#import "EucBook.h"
#import "EucBUpeLocalBookReference.h"
#import "EucCSSIntermediateDocument.h"

@class EucBookPageIndexPoint, EucCSSIntermediateDocument;
@protocol EucCSSDocumentTree, EucBUpeDataProvider;

@interface EucBUpeBook : EucBUpeLocalBookReference <EucBook, EucCSSIntermediateDocumentDataProvider> {
    id<EucBUpeDataProvider> _dataProvider;
    
    NSURL *_root;            // Root of the bundle.
    NSString *_tocNcxId;
        
    NSDictionary *_meta;
    NSArray *_spine;
    NSDictionary *_manifest; // id -> file, path relative to root.
    NSString *_coverPath;
        
    NSURL *_guideCoverItemURL;
    
    // From the TOC.
    // Pairs of name, path relative to _root, including URL fragment.
    NSArray *_navPoints; 
    
    NSDictionary *_idToIndexPoint;
    
    THCache *_documentCache;
    
    BOOL _persistsPositionAutomatically;
    int _currentPageIndexPointFD;
 
    EucBookPageIndexPoint *_currentPageIndexPoint;
    
    float *_indexSourceScaleFactors;
    
    CGFloat _normalisingScaleFactor;
}

// Some books have, for reasons known only to the publishers (and perhaps not 
// even to them...) crazy default text sizes.  This scale factor will scale 
// that text size to our default, and can be used to make the body text
// a uniform size across all books.
@property (nonatomic, assign, readonly) CGFloat normalisingScaleFactor;
@property (nonatomic, retain, readonly) NSURL *coverURL;

- (id)initWithDataProvider:(id<EucBUpeDataProvider>)dataProvider 
        cacheDirectoryPath:(NSString *)cacheDirectoryPath;

- (void)whitelistSectionsWithUuids:(NSSet *)uuids;

- (NSData *)dataForURL:(NSURL *)url;

- (EucCSSIntermediateDocument *)intermediateDocumentForIndexPoint:(EucBookPageIndexPoint *)indexPoint;
- (EucBookPageIndexPoint *)indexPointForId:(NSString *)identifier;

// Takes absolute file:/// url strings (/not/ persistable - they 
// may change on a iOS backup/restore).
@property (nonatomic, readonly, retain) NSDictionary *idToIndexPoint;

// Set to NO to not save the index point internally.
@property (nonatomic, assign) BOOL persistsPositionAutomatically; // default: YES;

// Override points.

// This class will try to be intelligent about caching document trees, data etc.
- (NSData *)dataForURL:(NSURL *)url;
- (id<EucCSSDocumentTree>)documentTreeForURL:(NSURL *)url;
- (NSURL *)documentURLForIndexPoint:(EucBookPageIndexPoint *)indexPoint;

- (NSDictionary *)buildIdToIndexPoint;

- (NSArray *)baseCSSPathsForDocumentTree:(id<EucCSSDocumentTree>)documentTree;
- (NSArray *)userCSSPathsForDocumentTree:(id<EucCSSDocumentTree>)documentTree;

// From the EucBook protocol - included here because it's useful for overriding
// for covers etc.
- (BOOL)fullBleedPageForIndexPoint:(EucBookPageIndexPoint *)indexPoint;

// Provide an array of floats specifying the percentage of the book that each
// index pont source accounts for.  Should sum to 1.
- (float *)indexSourceScaleFactors;

@end
