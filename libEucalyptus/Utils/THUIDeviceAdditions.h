//
//  THUIDeviceAdditions.h
//  Eucalyptus
//
//  Created by James Montgomerie on 26/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (THUIDeviceAdditions) 

- (uint32_t)nonidentifiableUniqueIdentifier;
- (NSComparisonResult)compareSystemVersion:(NSString *)otherVersion;

@end
