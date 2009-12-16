//
//  THAlertViewWithUserInfo.h
//  libEucalyptus
//
//  Created by James Montgomerie on 21/11/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface THAlertViewWithUserInfo : UIAlertView {
    id _userInfo;
}

@property (retain, nonatomic) id userInfo;

@end
