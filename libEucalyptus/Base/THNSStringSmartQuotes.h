//
//  THNSStringSmartQuotes.h
//  libEucalyptus
//
//  Created by James Montgomerie on 11/08/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (THNSStringSmartQuotes)

- (NSString *)stringWithSmartQuotesWithPreviousCharacter:(UniChar)previousCaracterIn;
- (NSString *)stringWithSmartQuotes;

@end
