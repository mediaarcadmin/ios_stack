//
//  BlioAlertManager.m
//  BlioApp
//
//  Created by Don Shin on 5/5/10.
//

#import "BlioAlertManager.h"

@implementation BlioAlertManager

@synthesize suppressedAlertTypes;

+(BlioAlertManager*)sharedInstance
{
	static BlioAlertManager * sharedAlertManager = nil;
	if (sharedAlertManager == nil) {
		sharedAlertManager = [[BlioAlertManager alloc] init];
		sharedAlertManager.suppressedAlertTypes = [NSMutableArray array];
	}
	
	return sharedAlertManager;
}

+(void)showAlert:(UIAlertView*)alert {
	[alert show];
}
+ (void)showAlertWithTitle:(NSString *)title
				   message:(NSString *)message
				  delegate:(id)delegate
		 cancelButtonTitle:(NSString *)cancelButtonTitle
		 otherButtonTitles:(NSString *)otherButtonTitles, ...
{
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title
                                                     message:message
                                                    delegate:delegate
                                           cancelButtonTitle:cancelButtonTitle
                                           otherButtonTitles:nil] autorelease];
    if (otherButtonTitles != nil) {
		[alert addButtonWithTitle:otherButtonTitles];
		va_list args;
		va_start(args, otherButtonTitles);
		NSString * title = nil;
		while((title = va_arg(args,NSString*))) {
			[alert addButtonWithTitle:title];
		}
		va_end(args);
    }
	
    [alert show];
}
+ (void)showAlertOfSuppressedType:(NSString*)alertType
							title:(NSString *)title
						 message:(NSString *)message
						delegate:(id)delegate
			   cancelButtonTitle:(NSString *)cancelButtonTitle
			   otherButtonTitles:(NSString *)otherButtonTitles, ...
{
	if ([[BlioAlertManager sharedInstance].suppressedAlertTypes containsObject:alertType]) return;
	[[BlioAlertManager sharedInstance].suppressedAlertTypes addObject:alertType];
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title
                                                     message:message
                                                    delegate:delegate
                                           cancelButtonTitle:cancelButtonTitle
                                           otherButtonTitles:nil] autorelease];
    if (otherButtonTitles != nil) {
		[alert addButtonWithTitle:otherButtonTitles];
		va_list args;
		va_start(args, otherButtonTitles);
		NSString * title = nil;
		while((title = va_arg(args,NSString*))) {
			[alert addButtonWithTitle:title];
		}
		va_end(args);
    }
	
    [alert show];	
}
+(void)removeSuppressionForAlertType:(NSString*)alertType {
	[[BlioAlertManager sharedInstance].suppressedAlertTypes removeObject:alertType];
}
-(void)dealloc {
	self.suppressedAlertTypes = nil;
	[super dealloc];
}
@end
