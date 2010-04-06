//
//  BlioLoginView.h
//  BlioApp
//
//  Created by Arnold Chien on 4/1/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioLoginManager.h"

@interface BlioLoginView : UIAlertView {
	BlioLoginManager* loginManager;
}

@property (nonatomic,retain) BlioLoginManager* loginManager;

- (void)display;

@end
