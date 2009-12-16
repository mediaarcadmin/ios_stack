//
//  THPair.h
//  libEucalyptus
//
//  Created by James Montgomerie on 15/07/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface THPair : NSObject <NSCopying> {
@public
    id first;
    id second;
}

@property (nonatomic, retain) id first;
@property (nonatomic, retain) id second;

- (id)initWithFirst:(id)firstIn second:(id)secondIn;
+ (id)pairWithFirst:(id)firstIn second:(id)secondIn;

@end


@interface NSMutableArray (THPairAdditions)

- (void)addPairWithFirst:(id)first second:(id)second;

@end