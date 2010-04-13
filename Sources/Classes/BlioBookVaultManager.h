//
//  BlioBookVaultManager.h
//  BlioApp
//
//  Created by Arnold Chien on 4/13/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioLoginManager.h"


@interface BlioBookVaultManager : NSObject {
	BlioLoginManager* loginManager;
	NSMutableArray* isbns; // array of ISBN numbers
}

@property (nonatomic, retain) BlioLoginManager* loginManager;

- (void)getContent:(NSString*)isbn;
- (void)archiveBooks;
- (void)downloadBook:(NSString*)isbn;

@end
