//
//  THTimer.h
//
//  Created by James Montgomerie on 26/04/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface THTimer : NSObject {
    NSString *_name;
    CFTimeInterval _creationTime;
    CFTimeInterval _runTime;
}

+ (id)timerWithName:(NSString *)name;
- (id)initWithName:(NSString *)name;

- (void)stop;
- (void)report;

@property (nonatomic, readonly) CFTimeInterval runTime; 
@end
