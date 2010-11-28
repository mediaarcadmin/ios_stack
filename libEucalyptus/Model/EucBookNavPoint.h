//
//  EucBookNavPoint.h
//  libEucalyptus
//
//  Created by James Montgomerie on 15/11/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EucBookNavPoint : NSObject {
    NSString *_text;
    NSString *_uuid;
    NSUInteger _level;
}

@property (nonatomic, copy, readonly) NSString *text;
@property (nonatomic, copy, readonly) NSString *uuid;
@property (nonatomic, assign, readonly) NSUInteger level;

- (id)initWithText:(NSString *)text uuid:(NSString *)uuid level:(NSUInteger)level;
+ (id)navPointWithText:(NSString *)text uuid:(NSString *)uuid level:(NSUInteger)level;

// Legacy code support - thses used to be pairs of [text, uuid];
@property (nonatomic, retain, readonly) id first;
@property (nonatomic, retain, readonly) id second;

@end
