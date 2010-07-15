//
//  EucConfiguration.h
//  libEucalyptus
//
//  Created by James Montgomerie on 28/05/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const EucConfigurationFontSizesKey;
extern NSString * const EucConfigurationDefaultFontSizeKey;
extern NSString * const EucConfigurationDefaultFontFamilyKey;
extern NSString * const EucConfigurationSerifFontFamilyKey;
extern NSString * const EucConfigurationSansSerifFontFamilyKey;
extern NSString * const EucConfigurationMonospaceFontFamilyKey;
extern NSString * const EucConfigurationCursiveFontFamilyKey;
extern NSString * const EucConfigurationFantasyFontFamilyKey;

@interface EucConfiguration : NSObject {
}

+ (id)objectForKey:(NSString *)key;

@end
