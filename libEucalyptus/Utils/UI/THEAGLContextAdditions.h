//
//  THEAGLContextAdditions.h
//  libEucalyptus
//
//  Created by James Montgomerie on 02/11/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <OpenGLES/EAGL.h>

@interface EAGLContext (THEAGLContextAdditions) 

- (void)thPush;
- (void)thPop;

@end
