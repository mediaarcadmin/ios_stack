//
//  EucEPubBook.h
//  Eucalyptus
//
//  Created by James Montgomerie on 28/07/2009.
//  Copyright 2009 James Montgomerie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucBook.h"
#import "EucEPubLocalBookReference.h"

@interface EucEPubBook : EucEPubLocalBookReference <EucBook> {
    NSURL *_root;
    NSURL *_contentURL;
    NSString *_tocNcxId;
    
    NSDictionary *_manifestOverrides;
    NSDictionary *_manifestUrlsToOverriddenUrls;
    
    NSDictionary *_meta;
    NSDictionary *_manifest;
    NSArray *_spine;
    NSDictionary *_anchorPoints;
    
    NSArray *_sections;
    NSArray *_filteredSections;
    
    int _currentPageIndexPointFD;
}

@property (nonatomic, readonly) NSArray *spineFiles;
@property (nonatomic, retain) NSString *coverPath;

- (id)initWithPath:(NSString *)path;
- (void)whitelistSectionsWithUUIDs:(NSSet *)uuids;

- (NSData *)dataForFileAtURL:(NSURL *)url;

@end
