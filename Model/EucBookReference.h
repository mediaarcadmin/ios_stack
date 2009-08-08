//
//  BookReference.h
//  Eucalyptus
//
//  Created by James Montgomerie on 29/05/2008.
//  Copyright 2008 James Montgomerie. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum BookAvailabilityState {
    BookAvailabilityRemote,
    BookAvailabilityDownloading,
    BookAvailabilityLocal,
} BookAvailabilityState;

@interface EucBookReference : NSObject

// Subclasses should implement:
@property (nonatomic, copy) NSString *etextNumber;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *author;

// Provided:
@property (nonatomic, readonly) NSString *humanReadableAuthor;
@property (nonatomic, readonly) NSString *humanReadableTitle;
- (NSComparisonResult)compare:(EucBookReference *)other;

@end

@interface NSString (BookReferenceAdditions) 
- (NSString *)humanReadableNameFromLibraryFormattedName;
@end