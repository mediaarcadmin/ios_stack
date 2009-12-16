//
//  EucEPubLocalBookReference.h
//  libEucalyptus
//
//  Created by James Montgomerie on 28/07/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucBookReference.h"
#import "EucLocalBookReference.h"

@interface EucEPubLocalBookReference : EucBookReference <EucLocalBookReference> {
@protected
    NSString *_title;
    NSString *_author;
    NSString *_etextNumber;
    NSString *_path;
}

@property (nonatomic, copy) NSString *path;

- (id)initWithTitle:(NSString *)title author:(NSString *)author etextNumber:(NSString *)etextNumber path:(NSString *)path;

@end
