//
//  BlioGestureSupressingContainerView.m
//  BlioApp
//
//  Created by Matt Farrugia on 16/03/2011.
//  Copyright 2011 BitWink. All rights reserved.
//

#import "BlioBlendView.h"
#import <QuartzCore/QuartzCore.h>

@implementation BlioBlendView

+ (Class)layerClass {
	return [CAReplicatorLayer class];
}

@end