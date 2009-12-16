//
//  THAlertViewWithUserInfo.m
//  libEucalyptus
//
//  Created by James Montgomerie on 21/11/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import "THAlertViewWithUserInfo.h"


@implementation THAlertViewWithUserInfo

@synthesize userInfo = _userInfo;

- (void)dealloc
{
    [_userInfo release];
    [super dealloc];
}

@end
