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

@interface BlioEPubXPSDataProvider ()

@property (nonatomic, retain) NSManagedObjectID *bookID;
@property (nonatomic, retain) BlioXPSProvider *xpsProvider;
@property (nonatomic, copy) NSString *ePubRootInXPS;

@end


@implementation BlioEPubXPSDataProvider

@synthesize bookID;
@synthesize xpsProvider;
@synthesize ePubRootInXPS;

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
        
        if(!self.xpsProvider) {
            [self release];
            self = nil;
        }          
    }
    return self;
}

- (void)dealloc
{
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
    return [self.xpsProvider dataForComponentAtPath:xpsPath];
}

@end
