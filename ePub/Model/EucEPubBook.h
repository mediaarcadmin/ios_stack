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
}

@property (nonatomic, readonly) NSArray *spineFiles;
@property (nonatomic, retain) NSString *coverPath;

- (id)initWithPath:(NSString *)path;
- (void)whitelistSectionsWithUuids:(NSSet *)uuids;

- (NSData *)dataForFileAtURL:(NSURL *)url;

@end
