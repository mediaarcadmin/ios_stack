//
//  BlioPDFFont.h
//  BlioApp
//
//  Created by Matt Farrugia on 05/02/2012.
//  Copyright (c) 2012 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlioPDFFont : NSObject

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *baseFont;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, retain) NSMutableDictionary *widths;
@property (nonatomic, assign) unichar notdef;
@property (nonatomic, assign) NSInteger missingWidth;
@property (nonatomic, assign) BOOL hasUnicodeMapping;

- (id)initWithKey:(NSString *)key;
- (NSInteger)glyphWidthForCharacter:(unichar)character;

@end
