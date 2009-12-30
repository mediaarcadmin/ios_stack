//
//  EucEPubBook.h
//  libEucalyptus
//
//  Created by James Montgomerie on 28/07/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucBook.h"
#import "EucEPubLocalBookReference.h"

@class EucEPubBookReader;
@protocol EucBookParagraph;

@interface EucEPubBook : EucEPubLocalBookReference <EucBook> {
    NSURL *_root;
    NSURL *_contentURL;
    NSString *_tocNcxId;
    
    NSDictionary *_anchorPoints;    

    NSDictionary *_meta;
    NSArray *_spine;
    NSDictionary *_manifest;

    NSDictionary *_manifestOverrides;
    NSDictionary *_manifestUrlsToOverriddenUrls;
        
    NSArray *_sections;
    NSArray *_filteredSections;
    
    int _currentPageIndexPointFD;
    
    EucEPubBookReader *_reader;
    id<EucBookParagraph> _cachedParagraph;
}

@property (nonatomic, readonly) NSArray *spineFiles;
@property (nonatomic, retain) NSString *coverPath;

- (id)initWithPath:(NSString *)path;
- (void)whitelistSectionsWithUuids:(NSSet *)uuids;

- (NSData *)dataForFileAtURL:(NSURL *)url;

- (NSArray *)paragraphWordsForParagraphWithId:(uint32_t)paragraphId;
- (uint32_t)paragraphIdForParagraphAfterParagraphWithId:(uint32_t)paragraphId;

- (void)getCurrentParagraphId:(uint32_t *)id wordOffset:(uint32_t *)wordOffset;

@end
