//
//  BlioTOCEntry.h
//  BlioApp
//
//  Created by Matt Farrugia on 01/12/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BlioTOCEntry: NSObject {
    NSString *name;
    NSUInteger startPage;
    NSUInteger level;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, assign) NSUInteger startPage;
@property (nonatomic, assign) NSUInteger level;

@end
