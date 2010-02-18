//
//  BlioBookmarkPoint.m
//  BlioApp
//
//  Created by James Montgomerie on 15/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioBookmark.h"

@implementation BlioBookmarkAbsolutePoint
 
@synthesize layoutPage;
@synthesize ePubParagraphId;
@synthesize ePubWordOffset;
@synthesize ePubHyphenOffset;

+ (BlioBookmarkAbsolutePoint *)bookmarkAbsolutePointWithBookmarkPoint:(BlioBookmarkPoint *)point {
    BlioBookmarkAbsolutePoint *absolutePoint = [[BlioBookmarkAbsolutePoint alloc] init];
    absolutePoint.layoutPage = point.layoutPage;
    absolutePoint.ePubParagraphId = point.paragraphOffset;
    absolutePoint.ePubWordOffset = point.wordOffset;
    absolutePoint.ePubHyphenOffset = point.hyphenOffset;
    
    return [absolutePoint autorelease];
}

@end

@implementation BlioBookmarkPoint

@synthesize layoutPage;
@synthesize paragraphOffset;
@synthesize wordOffset;
@synthesize hyphenOffset;

- (NSManagedObject *)persistentBookmarkPointInContext:(NSManagedObjectContext *)moc {
    NSManagedObject *newBookmarkPoint = [NSEntityDescription
                                    insertNewObjectForEntityForName:@"BlioBookmarkPoint"
                                    inManagedObjectContext:moc];
    
    [newBookmarkPoint setValue:[NSNumber numberWithInteger:self.layoutPage] forKey:@"layoutPage"];
    [newBookmarkPoint setValue:[NSNumber numberWithInteger:self.paragraphOffset] forKey:@"paragraphOffset"];
    [newBookmarkPoint setValue:[NSNumber numberWithInteger:self.wordOffset] forKey:@"wordOffset"];
    [newBookmarkPoint setValue:[NSNumber numberWithInteger:self.hyphenOffset] forKey:@"hyphenOffset"];   
    
    return newBookmarkPoint;
}

+ (BlioBookmarkPoint *)bookmarkPointWithAbsolutePoint:(BlioBookmarkAbsolutePoint *)absolutePoint {
    BlioBookmarkPoint *point = [[BlioBookmarkPoint alloc] init];
    point.layoutPage = absolutePoint.layoutPage;
    point.paragraphOffset = absolutePoint.ePubParagraphId;
    point.wordOffset = absolutePoint.ePubWordOffset;
    point.hyphenOffset = absolutePoint.ePubHyphenOffset;
    
    return [point autorelease];
}

+ (BlioBookmarkPoint *)bookmarkPointWithPersistentBookmarkPoint:(NSManagedObject *)persistedBookmarkPoint {
    BlioBookmarkPoint *point = [[BlioBookmarkPoint alloc] init];
    point.layoutPage = [[persistedBookmarkPoint valueForKey:@"layoutPage"] integerValue];
    point.paragraphOffset = [[persistedBookmarkPoint valueForKey:@"paragraphOffset"] integerValue];
    point.wordOffset = [[persistedBookmarkPoint valueForKey:@"wordOffset"] integerValue];
    point.hyphenOffset = [[persistedBookmarkPoint valueForKey:@"hyphenOffset"] integerValue]; 
    
    return [point autorelease]; 
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

+ (BOOL)bookmark:(NSManagedObject *)persistedBookmarkRange isEqualToBookmarkRange:(BlioBookmarkRange *)bookmarkRange {
    if (([[persistedBookmarkRange valueForKeyPath:@"range.startPoint.layoutPage"] integerValue] == bookmarkRange.startPoint.layoutPage) &&
        ([[persistedBookmarkRange valueForKeyPath:@"range.startPoint.paragraphOffset"] integerValue] == bookmarkRange.startPoint.paragraphOffset) &&
        ([[persistedBookmarkRange valueForKeyPath:@"range.startPoint.wordOffset"] integerValue] == bookmarkRange.startPoint.wordOffset) &&
        ([[persistedBookmarkRange valueForKeyPath:@"range.startPoint.hyphenOffset"] integerValue] == bookmarkRange.startPoint.hyphenOffset) &&
        ([[persistedBookmarkRange valueForKeyPath:@"range.endPoint.layoutPage"] integerValue] == bookmarkRange.endPoint.layoutPage) &&
        ([[persistedBookmarkRange valueForKeyPath:@"range.endPoint.paragraphOffset"] integerValue] == bookmarkRange.endPoint.paragraphOffset) &&
        ([[persistedBookmarkRange valueForKeyPath:@"range.endPoint.wordOffset"] integerValue] == bookmarkRange.endPoint.wordOffset) &&
        ([[persistedBookmarkRange valueForKeyPath:@"range.endPoint.hyphenOffset"] integerValue] == bookmarkRange.endPoint.hyphenOffset)) {
        return YES;
    } else {
        return NO;
    }
}

+ (BlioBookmarkRange *)bookmarkRangeWithBookmarkPoint:(BlioBookmarkPoint *)point {
    BlioBookmarkRange *range = [[BlioBookmarkRange alloc] init];
    range.startPoint = point;
    range.endPoint = point;
    
    return [range autorelease];
}

+ (BlioBookmarkRange *)bookmarkRangeWithPersistentBookmarkRange:(NSManagedObject *)persistedBookmarkRange {
    BlioBookmarkRange *range = [[BlioBookmarkRange alloc] init];
    range.startPoint = [BlioBookmarkPoint bookmarkPointWithPersistentBookmarkPoint:[persistedBookmarkRange valueForKey:@"startPoint"]];
    range.endPoint = [BlioBookmarkPoint bookmarkPointWithPersistentBookmarkPoint:[persistedBookmarkRange valueForKey:@"endPoint"]];
    range.color = [persistedBookmarkRange valueForKey:@"color"];
    
    return [range autorelease];
}

@end
