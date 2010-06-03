//
//  EucConfiguration.m
//  libEucalyptus
//
//  Created by James Montgomerie on 28/05/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucConfiguration.h"
#import "THLog.h"

@implementation EucConfiguration

NSString * const EucConfigurationFontSizesKey = @"EucFontSizes";
NSString * const EucConfigurationDefaultFontSizeKey = @"EucDefaultFontSize";
NSString * const EucConfigurationDefaultFontFamilyKey = @"EucDefaultFontFamily";
NSString * const EucConfigurationSerifFontFamilyKey = @"EucSerifFontFamily";
NSString * const EucConfigurationSansSerifFontFamilyKey = @"EucSansSerifFontFamily";
NSString * const EucConfigurationMonospaceFontFamilyKey = @"EucMonospaceFontFamily";
NSString * const EucConfigurationCursiveFontFamilyKey = @"EucCursiveFontFamily";
NSString * const EucConfigurationFantasyFontFamilyKey = @"EucFantasyFontFamily";

static NSDictionary *sEucConfigurationDictionary;

+ (void)initialize
{
    if(self == [EucConfiguration class]) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"EucConfiguration" ofType:@"plist"];
        NSAssert(path, @"Cannot find EucConfiguration.plist in bundle");

        sEucConfigurationDictionary = [[NSDictionary alloc] initWithContentsOfFile:path];
        NSAssert([sEucConfigurationDictionary isKindOfClass:[NSDictionary class]], path);
    }
}

+ (id)objectForKey:(NSString *)key
{
    return [sEucConfigurationDictionary objectForKey:key];
}

@end
