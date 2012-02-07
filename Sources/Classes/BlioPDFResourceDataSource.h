//
//  BlioPDFResourceDataSource.h
//  BlioApp
//
//  Created by Matt Farrugia on 05/02/2012.
//  Copyright (c) 2012 BitWink. All rights reserved.
//

@protocol BlioPDFResourceDataSource

- (id)fontWithName:(NSString *)name onPageRef:(CGPDFPageRef)pageRef;

@end
