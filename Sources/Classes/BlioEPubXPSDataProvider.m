//
//  BlioEPubXPSDataProvider.m
//  BlioApp
//
//  Created by James Montgomerie on 02/02/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioEPubXPSDataProvider.h"
#import "BlioXPSProvider.h"
#import "BlioBookManager.h"
#import "BlioBook.h"

#import "NSString+BlioAdditions.h"
#import <objc/runtime.h>

@interface BlioEPubXPSDataProvider ()

@property (nonatomic, retain) NSManagedObjectID *bookID;
@property (nonatomic, retain) BlioXPSProvider *xpsProvider;
@property (nonatomic, copy) NSString *ePubRootInXPS;
@property (nonatomic, copy) NSString *title;

@end


@implementation BlioEPubXPSDataProvider

@synthesize bookID;
@synthesize xpsProvider;
@synthesize ePubRootInXPS;
@synthesize title;

- (id)initWithWithBookID:(NSManagedObjectID *)aBookID
{
    if((self = [super init])) {
        self.bookID = aBookID;
                
        BlioBookManager *manager = [BlioBookManager sharedBookManager];
        BlioBook *book = [manager bookWithID:aBookID];
        
        NSString *myEPubRootInXPS = [book manifestRelativePathForKey:BlioManifestEPubKey];
        if(myEPubRootInXPS) {
            self.ePubRootInXPS = myEPubRootInXPS;
            self.xpsProvider = [manager checkOutXPSProviderForBookWithID:aBookID];
        }
        
        self.title = book.title;
        
        if(!self.xpsProvider) {
            [self release];
            self = nil;
        }          
    }
    return self;
}

- (void)dealloc
{
    self.title = nil;
    self.ePubRootInXPS = nil;
    if(self.xpsProvider) {
        self.xpsProvider = nil;
        [[BlioBookManager sharedBookManager] checkInXPSProviderForBookWithID:self.bookID];
    }
    self.bookID = nil;
    
    [super dealloc];
}

- (NSData *)dataForComponentAtPath:(NSString *)path
{
    NSString *xpsPath = [self.ePubRootInXPS stringByAppendingPathComponent:path];
    NSData *ret = [self.xpsProvider dataForComponentAtPath:xpsPath];
    
#if 1
    
#if TARGET_IPHONE_SIMULATOR
    
    // For debugging purposes, write out the decoded files to /tmp.
    // The above #if stop this compiling  in checked in code (should be #if 0!)
    // and on device builds ever.
    
    NSFileManager *manager = [[NSFileManager alloc] init];
    
    NSString *tempOutputXPSPath = (NSString *)objc_getAssociatedObject(self, @"BlioEPubXPSDataProviderTmpPath");
    if(!tempOutputXPSPath) {
        tempOutputXPSPath = [@"/tmp" stringByAppendingPathComponent:[NSString uniqueStringWithBaseString:self.title]];
        objc_setAssociatedObject(self, @"BlioEPubXPSDataProviderTmpPath", tempOutputXPSPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    NSString *pathInXPS = [path stringByDeletingLastPathComponent];
    NSString *tempOutputInnerDir;
    if(pathInXPS.length) {
        tempOutputInnerDir = [tempOutputXPSPath stringByAppendingPathComponent:pathInXPS];
    } else {
        tempOutputInnerDir = tempOutputXPSPath;
    }
    [manager createDirectoryAtPath:tempOutputInnerDir withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSString *fullTempOutputPath = [tempOutputInnerDir stringByAppendingPathComponent:[path lastPathComponent]];
    [ret writeToFile:fullTempOutputPath atomically:NO];
    
    [manager release];
    
#endif // TARGET_IPHONE_SIMULATOR
    
#endif
    
    return ret;
}

@end
