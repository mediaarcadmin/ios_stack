//
//  BlioEPubBook.m
//  BlioApp
//
//  Created by James Montgomerie on 06/07/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioEPubBook.h"
#import "BlioBookManager.h"

@implementation BlioEPubBook

@synthesize blioBookID;

- (void)dealloc
{
    self.blioBookID = nil;
    
    [super dealloc];
}

@end
