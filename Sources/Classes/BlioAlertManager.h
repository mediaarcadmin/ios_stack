//
//  BlioAlertManager.h
//  BlioApp
//
//  Created by Don Shin on 5/5/10.
//

#import <Foundation/Foundation.h>

@interface BlioAlertManager : NSObject {

}
+(BlioAlertManager*)sharedInstance;
+(void)showAlert:(UIAlertView*)alert;
+(void)showAlertWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...;
@end
