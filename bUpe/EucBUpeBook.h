//
//  EucBUpeBook.h
//  libEucalyptus
//
//  Created by James Montgomerie on 12/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucBook.h"
#import "EucBUpeLocalBookReference.h"
#import "EucCSSIntermediateDocument.h"

@class EucBookPageIndexPoint, EucCSSIntermediateDocument;
@protocol EucCSSDocumentTree;

@interface EucBUpeBook : EucBUpeLocalBookReference <EucBook, EucCSSIntermediateDocumentDataSource> {
    NSURL *_root;            // Root of the bundle.
    NSString *_tocNcxId;
        
    NSDictionary *_meta;
    NSArray *_spine;
    NSDictionary *_manifest; // id -> file, path relative to root.
    NSString *_coverPath;
    
    NSDictionary *_manifestOverrides; // id -> file, path relative to root.
    NSDictionary *_manifestUrlsToOverriddenUrls; // Full URL from manifest -> full URL in overrides.
    
    // From the TOC.
    // Pairs of name, path relative to _root, including URL fragment.
    NSArray *_navPoints; 
    
    NSMutableArray *_documentCache;
    
    
    BOOL _persistsPositionAutomatically;
    int _currentPageIndexPointFD;
 
    EucBookPageIndexPoint *_currentPageIndexPoint;
}

@property (nonatomic, retain) NSString *coverPath;

- (id)initWithPath:(NSString *)path;
- (void)whitelistSectionsWithUuids:(NSSet *)uuids;

- (NSData *)dataForURL:(NSURL *)url;

// Takes fragment IDs as paths relative to _root URL.
- (void)setCurrentPageIndexPointForId:(NSString *)uuid;

- (EucCSSIntermediateDocument *)intermediateDocumentForIndexPoint:(EucBookPageIndexPoint *)point;

// Set to NO to not save the index point internally.
@property (nonatomic, assign) BOOL persistsPositionAutomatically; // default: YES;

// Override points.

// This class will try to be intelligent about caching document trees, data etc.
- (NSData *)dataForURL:(NSURL *)url;
- (id<EucCSSDocumentTree>)documentTreeForURL:(NSURL *)url;
- (NSURL *)documentURLForIndexPoint:(EucBookPageIndexPoint *)point;
- (EucBookPageIndexPoint *)indexPointForId:(NSString *)identifier;

// Default is YES.  Controls whether to look for a HEAD element in the supplied
// document trees to parse for CSS etc.
- (BOOL)documentTreeIsHTML:(id<EucCSSDocumentTree>)documentTree;
- (NSString *)baseCSSPathForDocumentTree:(id<EucCSSDocumentTree>)documentTree;

// From the EucBook protocol - included here because it's useful for overriding
// for covers etc.
- (BOOL)fullBleedPageForIndexPoint:(EucBookPageIndexPoint *)indexPoint;


@end
