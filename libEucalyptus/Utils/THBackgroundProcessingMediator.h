//
//  THBackgroundProcessingMediator.h
//  libEucalyptus
//
//  Created by James Montgomerie on 05/12/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface THBackgroundProcessingMediator : NSObject {
}

+ (void)sleepIfBackgroundProcessingCurtailed;
+ (void)curtailBackgroundProcessing;
+ (void)allowBackgroundProcessing;

@end
