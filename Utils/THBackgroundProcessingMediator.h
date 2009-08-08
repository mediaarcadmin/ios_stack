//
//  THBackgroundProcessingMediator.h
//  Eucalyptus
//
//  Created by James Montgomerie on 05/12/2008.
//  Copyright 2008 James Montgomerie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface THBackgroundProcessingMediator : NSObject {
}

+ (void)sleepIfBackgroundProcessingCurtailed;
+ (void)curtailBackgroundProcessing;
+ (void)allowBackgroundProcessing;

@end
