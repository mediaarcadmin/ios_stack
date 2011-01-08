//
//  BlioAlertManager.h
//  BlioApp
//
//  Created by Don Shin on 5/5/10.
//

#import <Foundation/Foundation.h>

@interface BlioAlertManager : NSObject {
	NSMutableArray * suppressedAlertTypes;
}
@property (nonatomic,retain) NSMutableArray * suppressedAlertTypes;

+(BlioAlertManager*)sharedInstance;
+(void)showAlert:(UIAlertView*)alert;
+(void)showAlertOfSuppressedType:(NSString*)alertType title:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...;
+(void)showAlertWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...;
+(void)removeSuppressionForAlertType:(NSString*)alertType;
@end
