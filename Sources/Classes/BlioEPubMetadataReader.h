//
//  BlioEPubMetadataReader.h
//  BlioApp
//
//  Created by James Montgomerie on 05/03/2012.
//  Copyright (c) 2012 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BlioEPubMetadataReaderDataProvider;

@interface BlioEPubMetadataReader : NSObject

@property (nonatomic, assign, readonly) BOOL hasRightsXML;

@property (nonatomic, assign, readonly) BOOL hasEncryptionXML;
@property (nonatomic, retain, readonly) NSString *unknownEncryptionAlgorithm;

@property (nonatomic, assign, readonly) BOOL hasContainerXML;

@property (nonatomic, assign, readonly) BOOL hasPackageFile;

@property (nonatomic, retain, readonly) NSDecimalNumber *packageVersion;
@property (nonatomic, retain, readonly) NSString *title;
@property (nonatomic, retain, readonly) NSArray *authors;

- (id)initWithDataProvider:(id<BlioEPubMetadataReaderDataProvider>)dataProvider;

@end

@protocol BlioEPubMetadataReaderDataProvider <NSObject>

- (BOOL)blioEPubMetadataReader:(BlioEPubMetadataReader *)reader componentExistsAtPath:(NSString *)path;
- (NSData *)blioEPubMetadataReader:(BlioEPubMetadataReader *)reader copyDataForComponentAtPath:(NSString *)path;

@end