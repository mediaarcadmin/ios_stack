/*
 *  BlioStoreHelperDelegate.h
 *  BlioApp
 *
 *  Created by Don Shin on 5/7/10.
 *  Copyright 2010 CrossComm, Inc. All rights reserved.
 *
 */

@class BlioStoreHelper;


@protocol BlioStoreHelperDelegate

-(void)storeHelper:(BlioStoreHelper*)loginHelper receivedLoginResult:(NSInteger)loginResult;

@end
