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
    
    NSDictionary *_manifest;
    NSArray *_spine;
    NSDictionary *_anchorPoints;
    
    NSArray *_sections;
    NSArray *_filteredSections;
    uint32_t _filteredEndOfBookByteOffset;
    
    int _currentPageIndexPointFD;
}

@property (nonatomic, readonly) NSArray *spineFiles;

- (id)initWithPath:(NSString *)path;
- (void)hideSectionsAfterSectionWithUUID:(NSString *)uuid;

@end
