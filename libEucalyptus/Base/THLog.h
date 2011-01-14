//
//  THLog.h
//
//  Created by James Montgomerie on 24/04/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

extern BOOL __THgShouldLog;
extern BOOL __THgShouldLogVerbose;

#define THProcessLoggingDefaults() ([[NSUserDefaults standardUserDefaults] boolForKey:@"THShouldLog"]?(__THgShouldLog = YES):NO, [[NSUserDefaults standardUserDefaults] boolForKey:@"THShouldLogVerbose"]?(__THgShouldLogVerbose = YES):NO)
#define THLog(FMT,...) do { if(__THgShouldLog) NSLog(FMT, ##__VA_ARGS__); } while(0)
#define THLogVerbose(FMT,...) do { if(__THgShouldLog && __THgShouldLogVerbose) NSLog(FMT, ##__VA_ARGS__); } while(0)
#define THWarn(FMT,...) NSLog(@"WARNING: " FMT, ##__VA_ARGS__)
#define THWillLog() __THgShouldLog
#define THWillLogVerbose() __THgShouldLogVerbose