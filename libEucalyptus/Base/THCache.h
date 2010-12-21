//
//  THCache.h
//  libEucalyptus
//
//  Created by James Montgomerie on 30/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif

#import "THCacheBase.h"

@interface THCache : THCacheBase <THCacheItemInUse> {}

- (void)cacheObject:(id)value forKey:(id)key;
- (id)objectForKey:(id)key;

@end

@interface NSObject (THCacheObjectInUse)

- (BOOL)thCacheObjectInUse;

@end

@interface THIntegerToObjectCache : THCacheBase <THCacheItemInUse> {}

- (void)cacheObject:(id)value forKey:(uint32_t)key;
- (id)objectForKey:(uint32_t)key;

@end

@interface THStringAndIntegerToObjectCache : THCacheBase <THCacheItemInUse> {}

- (void)cacheObject:(id)value forStringKey:(NSString *)stringKey integerKey:(uint32_t)integerKey;
- (id)objectForStringKey:(NSString *)stringKey integerKey:(uint32_t)integerKey;

@end


@interface THStringAndFloatToCGFloatCache : THCacheBase {}

- (void)cacheCGFloat:(CGFloat)value forStringKey:(NSString *)stringKey cgFloatKet:(CGFloat)cgFloatKey;
- (CGFloat)cgFloatForStringKey:(NSString *)stringKey cgFloatKet:(CGFloat)cgFloatKey;

@end