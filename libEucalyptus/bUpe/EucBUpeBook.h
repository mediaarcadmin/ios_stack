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
    
    NSDictionary *_manifestOverrides; // id -> file, path relative to root.
    NSDictionary *_manifestUrlsToOverriddenUrls; // Full URL from manifest -> full URL in overrides.
    
    // From the TOC.
    // Pairs of name, path relative to _root, including URL fragment.
    NSArray *_navPoints; 
    
    NSMutableArray *_documentCache;
    
    int _currentPageIndexPointFD;
}

@property (nonatomic, retain) NSString *coverPath;

- (id)initWithPath:(NSString *)path;
- (void)whitelistSectionsWithUuids:(NSSet *)uuids;

- (NSData *)dataForURL:(NSURL *)url;

// Takes fragment IDs as paths relative to _root URL.
- (void)setCurrentPageIndexPointForId:(NSString *)uuid;
- (EucBookPageIndexPoint *)indexPointForId:(NSString *)identifier;


// Override points.
- (NSData *)dataForURL:(NSURL *)url;
- (id<EucCSSDocumentTree>)documentTreeForURL:(NSURL *)url;
- (EucCSSIntermediateDocument *)intermediateDocumentForURL:(NSURL *)url;
- (EucCSSIntermediateDocument *)intermediateDocumentForIndexPoint:(EucBookPageIndexPoint *)point;

@end
