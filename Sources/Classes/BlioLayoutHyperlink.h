//
//  BlioLayoutHyperlink.h
//  BlioApp
//
//  Created by matt on 06/10/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlioLayoutHyperlink : NSObject {
    NSString *link;
    NSValue *rectValue;
}

@property (nonatomic, retain) NSString *link;
@property (nonatomic, assign) CGRect rect;

- (id)initWithLink:(NSString *)aLink rect:(CGRect)aRect;

@end
