//
//  BlioBookmark.h
//  BlioApp
//
//  Created by James Montgomerie on 15/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//
#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@class BlioBookmarkPoint;

@interface BlioBookmarkAbsolutePoint : NSObject {
    NSInteger layoutPage;
    uint32_t ePubBlockId;
    uint32_t ePubWordOffset;
    uint32_t ePubHyphenOffset;
}

@property (nonatomic, assign) NSInteger layoutPage;
@property (nonatomic, assign) uint32_t ePubBlockId;
@property (nonatomic, assign) uint32_t ePubWordOffset;
@property (nonatomic, assign) uint32_t ePubHyphenOffset;

+ (BlioBookmarkAbsolutePoint *)bookmarkAbsolutePointWithBookmarkPoint:(BlioBookmarkPoint *)point;

@end

@interface BlioBookmarkPoint : NSObject {
    NSInteger layoutPage;
    uint32_t blockOffset;
    uint32_t wordOffset;
    uint32_t elementOffset;
}

@property (nonatomic, assign) NSInteger layoutPage;
@property (nonatomic, assign) uint32_t blockOffset;
@property (nonatomic, assign) uint32_t wordOffset;
@property (nonatomic, assign) uint32_t elementOffset;

- (NSManagedObject *)persistentBookmarkPointInContext:(NSManagedObjectContext *)moc;
+ (BlioBookmarkPoint *)bookmarkPointWithAbsolutePoint:(BlioBookmarkAbsolutePoint *)absolutePoint;
+ (BlioBookmarkPoint *)bookmarkPointWithPersistentBookmarkPoint:(NSManagedObject *)persistedBookmarkPoint;

@end

@interface BlioBookmarkRange : NSObject {
    BlioBookmarkPoint *startPoint;
    BlioBookmarkPoint *endPoint;
    UIColor *color;
}

@property (nonatomic, retain) BlioBookmarkPoint *startPoint;
@property (nonatomic, retain) BlioBookmarkPoint *endPoint;
@property (nonatomic, retain) UIColor *color;

- (NSManagedObject *)persistentBookmarkRangeInContext:(NSManagedObjectContext *)moc;
+ (BOOL)bookmark:(NSManagedObject *)persistedBookmarkRange isEqualToBookmarkRange:(BlioBookmarkRange *)bookmarkRange;
+ (BlioBookmarkRange *)bookmarkRangeWithBookmarkPoint:(BlioBookmarkPoint *)point;
+ (BlioBookmarkRange *)bookmarkRangeWithPersistentBookmarkRange:(NSManagedObject *)persistedBookmarkRange;

@end
