//
//  BlioBookmarkPoint.m
//  BlioApp
//
//  Created by James Montgomerie on 15/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioBookmark.h"

@implementation BlioBookmarkPoint

@synthesize layoutPage;
@synthesize blockOffset;
@synthesize wordOffset;
@synthesize elementOffset;

- (NSManagedObject *)persistentBookmarkPointInContext:(NSManagedObjectContext *)moc {
    NSManagedObject *newBookmarkPoint = [NSEntityDescription
                                    insertNewObjectForEntityForName:@"BlioBookmarkPoint"
                                    inManagedObjectContext:moc];
    
    [newBookmarkPoint setValue:[NSNumber numberWithInteger:self.layoutPage] forKey:@"layoutPage"];
    [newBookmarkPoint setValue:[NSNumber numberWithInteger:self.blockOffset] forKey:@"blockOffset"];
    [newBookmarkPoint setValue:[NSNumber numberWithInteger:self.wordOffset] forKey:@"wordOffset"];
    [newBookmarkPoint setValue:[NSNumber numberWithInteger:self.elementOffset] forKey:@"elementOffset"];   
    
    return newBookmarkPoint;
}

+ (BlioBookmarkPoint *)bookmarkPointWithPersistentBookmarkPoint:(NSManagedObject *)persistedBookmarkPoint {
    BlioBookmarkPoint *point = [[BlioBookmarkPoint alloc] init];
    point.layoutPage = [[persistedBookmarkPoint valueForKey:@"layoutPage"] integerValue];
    point.blockOffset = [[persistedBookmarkPoint valueForKey:@"blockOffset"] integerValue];
    point.wordOffset = [[persistedBookmarkPoint valueForKey:@"wordOffset"] integerValue];
    point.elementOffset = [[persistedBookmarkPoint valueForKey:@"elementOffset"] integerValue]; 
    
    return [point autorelease]; 
}

- (id)copyWithZone:(NSZone *)zone
{
    return NSCopyObject(self, 0, zone);
}

- (NSComparisonResult)compare:(BlioBookmarkPoint *)rhs
{
    NSInteger comparison = self.layoutPage - rhs.layoutPage;
    if(comparison < 0) {
        return NSOrderedAscending;
    } else if (comparison > 0) {
        return NSOrderedDescending;
    } else {            
        comparison = self.blockOffset - rhs.blockOffset;
        if(comparison < 0) {
            return NSOrderedAscending;
        } else if (comparison > 0) {
            return NSOrderedDescending;
        } else {            
            comparison = self.wordOffset - rhs.wordOffset;
            if(comparison < 0) {
                return NSOrderedAscending;
            } else if (comparison > 0) {
                return NSOrderedDescending;
            } else {            
                comparison = self.elementOffset - rhs.elementOffset;
                if(comparison < 0) {
                    return NSOrderedAscending;
                } else if (comparison > 0) {
                    return NSOrderedDescending;
                } else {            
                    return NSOrderedSame;
                }
            }        
        }
    }
}

@end

@implementation BlioBookmarkRange

@synthesize startPoint, endPoint, color;

- (void)dealloc {
    self.startPoint = nil;
    self.endPoint = nil;
    self.color = nil;
    [super dealloc];
}

- (NSManagedObject *)persistentBookmarkRangeInContext:(NSManagedObjectContext *)moc {
    NSManagedObject *startBookmarkPoint = [self.startPoint persistentBookmarkPointInContext:moc];
    NSManagedObject *endBookmarkPoint = [self.endPoint persistentBookmarkPointInContext:moc];
            
    NSManagedObject *newBookmarkRange = [NSEntityDescription
                                    insertNewObjectForEntityForName:@"BlioBookmarkRange"
                                    inManagedObjectContext:moc];
    
    [newBookmarkRange setValue:startBookmarkPoint forKey:@"startPoint"];
    [newBookmarkRange setValue:endBookmarkPoint forKey:@"endPoint"];
    [newBookmarkRange setValue:self.color forKey:@"color"];

    return newBookmarkRange;
}

- (BOOL)isEqual:(id)object {
    BlioBookmarkRange *otherRange = (BlioBookmarkRange *)object;
    
    if ((otherRange.startPoint.layoutPage == self.startPoint.layoutPage) &&
        (otherRange.startPoint.blockOffset == self.startPoint.blockOffset) &&
        (otherRange.startPoint.wordOffset == self.startPoint.wordOffset) &&
        (otherRange.startPoint.elementOffset == self.startPoint.elementOffset) &&
        (otherRange.endPoint.layoutPage == self.endPoint.layoutPage) &&
        (otherRange.endPoint.blockOffset == self.endPoint.blockOffset) &&
        (otherRange.endPoint.wordOffset == self.endPoint.wordOffset) &&
        (otherRange.endPoint.elementOffset == self.endPoint.elementOffset)) {
        return YES;
    } else {
        return NO;
    }
}

+ (BOOL)bookmark:(NSManagedObject *)persistedBookmarkRange isEqualToBookmarkRange:(BlioBookmarkRange *)bookmarkRange {
    if (([[persistedBookmarkRange valueForKeyPath:@"range.startPoint.layoutPage"] integerValue] == bookmarkRange.startPoint.layoutPage) &&
        ([[persistedBookmarkRange valueForKeyPath:@"range.startPoint.blockOffset"] integerValue] == bookmarkRange.startPoint.blockOffset) &&
        ([[persistedBookmarkRange valueForKeyPath:@"range.startPoint.wordOffset"] integerValue] == bookmarkRange.startPoint.wordOffset) &&
        ([[persistedBookmarkRange valueForKeyPath:@"range.startPoint.elementOffset"] integerValue] == bookmarkRange.startPoint.elementOffset) &&
        ([[persistedBookmarkRange valueForKeyPath:@"range.endPoint.layoutPage"] integerValue] == bookmarkRange.endPoint.layoutPage) &&
        ([[persistedBookmarkRange valueForKeyPath:@"range.endPoint.blockOffset"] integerValue] == bookmarkRange.endPoint.blockOffset) &&
        ([[persistedBookmarkRange valueForKeyPath:@"range.endPoint.wordOffset"] integerValue] == bookmarkRange.endPoint.wordOffset) &&
        ([[persistedBookmarkRange valueForKeyPath:@"range.endPoint.elementOffset"] integerValue] == bookmarkRange.endPoint.elementOffset)) {
        return YES;
    } else {
        return NO;
    }
}

+ (BlioBookmarkRange *)bookmarkRangeWithBookmarkPoint:(BlioBookmarkPoint *)point {
    if (point) {
        BlioBookmarkRange *range = [[BlioBookmarkRange alloc] init];
        range.startPoint = point;
        range.endPoint = point;
    
        return [range autorelease];
    } else {
        return nil;
    }
}

+ (BlioBookmarkRange *)bookmarkRangeWithPersistentBookmarkRange:(NSManagedObject *)persistedBookmarkRange {
    BlioBookmarkRange *range = [[BlioBookmarkRange alloc] init];
    [range setStartPoint:[BlioBookmarkPoint bookmarkPointWithPersistentBookmarkPoint:[persistedBookmarkRange valueForKey:@"startPoint"]]];
    [range setEndPoint:[BlioBookmarkPoint bookmarkPointWithPersistentBookmarkPoint:[persistedBookmarkRange valueForKey:@"endPoint"]]];
    [range setColor:[persistedBookmarkRange valueForKey:@"color"]];
    
    return [range autorelease];
}

@end
