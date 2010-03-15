//
//  EucEPubLocalBookReference.m
//  libEucalyptus
//
//  Created by James Montgomerie on 28/07/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import "EucBUpeLocalBookReference.h"
#import "THNSFileManagerAdditions.h"


@implementation EucBUpeLocalBookReference

@synthesize title = _title;
@synthesize author = _author;
@synthesize path = _path;
@synthesize etextNumber = _etextNumber;

- (id)initWithTitle:(NSString *)title author:(NSString *)author etextNumber:(NSString *)etextNumber path:(NSString *)path
{
    if((self = [super init])) {
        if([title length]) _title = [title copy]; else _title = @"";
        if([author length]) _author = [author copy]; else _author = @"";
        if([etextNumber length]) _etextNumber = [etextNumber copy]; else _author = @"";
        _path = [path copy];
    }
    return self;
}

- (NSInteger)indexVersion
{
    return [[NSFileManager defaultManager] uint64ExtendedAttributeWithName:kXAttrIndexVersion ofItemAtPath:self.path];
}

- (void)setIndexVersion:(NSInteger)indexVersion
{
    [[NSFileManager defaultManager] setUint64ExtendedAttributeWithName:kXAttrIndexVersion ofItemAtPath:self.path to:indexVersion];
}

- (NSInteger)parserVersion
{
    return [[NSFileManager defaultManager] uint64ExtendedAttributeWithName:kXAttrParserVersion ofItemAtPath:self.path];
}

- (void)setParserVersion:(NSInteger)parserVersion
{
    [[NSFileManager defaultManager] setUint64ExtendedAttributeWithName:kXAttrParserVersion ofItemAtPath:self.path to:parserVersion];
}

- (BOOL)parsingIsComplete
{
    return YES;
}

- (BOOL)paginationIsComplete
{
    return NO;
}

- (CGFloat)percentThroughBook
{
    return 0;
}


- (CGFloat)percentPaginated
{
    return 0;
}


- (CGFloat)percentAnalysed
{
    return 100;
}


- (void)dealloc
{
    [_title release];
    [_author release];
    [_path release];
    [_etextNumber release];
    [super dealloc];
}

@end
