//
//  main.m
//  Paginate
//
//  Created by James Montgomerie on 05/08/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "THLog.h"

int main(int argc, char *argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    THProcessLoggingDefaults();
    int retVal = UIApplicationMain(argc, argv, nil, nil);
    [pool release];
    return retVal;
}
