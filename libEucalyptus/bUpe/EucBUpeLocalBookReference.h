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

@interface EucBUpeLocalBookReference : EucBookReference <EucLocalBookReference> {
@protected
    NSString *_title;
    NSString *_author;
    NSString *_etextNumber;
}

@property (nonatomic, copy) NSString *author;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *etextNumber;

@end
