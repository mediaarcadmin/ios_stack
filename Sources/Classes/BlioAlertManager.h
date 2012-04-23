//
//  BlioAlertManager.h
//  BlioApp
//
//  Created by Don Shin on 5/5/10.
//

#import <Foundation/Foundation.h>

@interface BlioAlertManager : NSObject {
	NSMutableDictionary * suppressedAlertTypes;
}
@property (nonatomic,retain) NSMutableDictionary * suppressedAlertTypes;

+(BlioAlertManager*)sharedInstance;
+(void)showAlert:(UIAlertView*)alert;
+(void)showAlertOfSuppressedType:(NSString*)alertType title:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...;
+(void)showAlertWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...;
+(void)showTaggedAlertWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate tag:(NSInteger)tag cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...;
+(void)removeSuppressionForAlertType:(NSString*)alertType;
@end
