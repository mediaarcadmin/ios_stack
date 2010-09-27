//
//  NSObject+BlioAdditions.h
//  BlioApp
//
//  Created by James Montgomerie on 02/07/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSObject (BlioAdditions)

- (id)blioPerformSelectorOnMainThreadReturningResult:(SEL)aSelector;
- (id)blioPerformSelectorOnMainThreadReturningResult:(SEL)aSelector withObjects:(id)arg1, ...;

@end
