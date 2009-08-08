//
//  BookSection.m
//  Eucalyptus
//
//  Created by James Montgomerie on 22/05/2008.
//  Copyright 2008 James Montgomerie. All rights reserved.
//

#import "EucBookSection.h"
#import "THLog.h"

NSString * const kBookSectionPrefix = @"Prefix";
NSString * const kBookSectionContents = @"Contents";
NSString * const kBookSectionIllustrationTable = @"IllustrationTable";
NSString * const kBookSectionChapter = @"Chapter";
NSString * const kBookSectionNondescript = @"Nondescript";
NSString * const kBookSectionIllustrationReference = @"IllustrationReference";

NSString * const kBookSectionPropertyTitle = @"Title";
NSString * const kBookSectionPropertyContentsList = @"ContentsList";

@implementation EucBookSection

@synthesize uuid = _uuid;
@synthesize kind = _kind;
@synthesize startOffset = _startOffset;
@synthesize endOffset = _endOffset;
@synthesize properties = _properties;
@synthesize subsections = _subsections;

- (NSString *)description
{
    return [NSString stringWithFormat:@"Section of kind %@, title \"%@\"", self.kind, [self.properties objectForKey:kBookSectionPropertyTitle]];
}

- (id)init
{
    if((self = [super init])) {
        CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
        _uuid = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
        CFRelease(uuid);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if((self = [super init])) {
        _uuid = [[coder decodeObjectForKey:@"uuid"] retain];
        _kind = [[coder decodeObjectForKey:@"kind"] retain];
        _startOffset = [coder decodeInt64ForKey:@"startOffset"];
        _endOffset = [coder decodeInt64ForKey:@"endOffset"];
        _properties = [[coder decodeObjectForKey:@"properties"] retain];
        _subsections = [[coder decodeObjectForKey:@"subsections"] retain];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_uuid forKey:@"uuid"];
    [coder encodeObject:_kind forKey:@"kind"];
    [coder encodeInt64:_startOffset forKey:@"startOffset"];
    [coder encodeInt64:_endOffset forKey:@"endOffset"];
    if(_properties) {
        [coder encodeObject:_properties forKey:@"properties"];
    }
    if(_subsections) {
        [coder encodeObject:_subsections forKey:@"subsections"];
    }
}

- (void)dealloc
{
    [_uuid release];
    [_kind release];
    [_properties release];
    [_subsections release];
    [super dealloc];
}

- (void)setProperty:(NSString *)property forKey:(NSString *)key
{
    if(!_properties) {
        _properties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:property, key, nil];
    } else {
        [_properties setObject:property forKey:key];
    }
}

- (void)addSubsection:(EucBookSection *)subsection
{
    if(!_subsections) {
        _subsections = [[NSMutableArray alloc] initWithObjects:subsection, nil];
    } else {
        [_subsections addObject:subsection];
    }
}

- (NSComparisonResult)compare:(EucBookSection *)rhs
{
    if(rhs.startOffset < _startOffset) {
        return NSOrderedDescending;
    } else if(rhs.startOffset > _startOffset) {
        return NSOrderedAscending;
    }
    return NSOrderedSame;
}

@end

// For compatibility with old NSCoder-written files:

@interface BookSection : EucBookSection {}
@end

@implementation BookSection
@end

