//
//  TransitionTestMain.m
//  TransitionTest
//
//  Created by James Montgomerie on 29/11/2009.
//  Copyright Things Made Out Of Other Things 2009. All rights reserved.
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
