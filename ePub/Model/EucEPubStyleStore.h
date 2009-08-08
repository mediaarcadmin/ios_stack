//
//  EucEPubStyleStore.h
//  Eucalyptus
//
//  Created by James Montgomerie on 25/07/2009.
//  Copyright 2009 James Montgomerie. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EucBookTextStyle;

@interface EucEPubStyleStore : NSObject {
    NSMutableDictionary *_selectorToStyle;
}

- (void)addStylesFromCSSFile:(NSString *)path;

- (EucBookTextStyle *)styleForSelector:(NSString *)selector fromStyle:(EucBookTextStyle *)style;
- (EucBookTextStyle *)styleWithInlineStyleDeclaration:(char *)inlineStyleDeclaration fromStyle:(EucBookTextStyle *)style;

/*
- (BookTextStyle *)styleForSelector:(NSString *)selector;
- (BookTextStyle *)styleForClassName:(NSString *)className; // A shortcut, so you don't need to prepend '.'
*/
@end
