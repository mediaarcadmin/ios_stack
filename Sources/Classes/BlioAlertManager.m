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
		sharedAlertManager.suppressedAlertTypes = [NSMutableDictionary dictionary];
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
                                           otherButtonTitles:otherButtonTitles, nil] autorelease];
    if (otherButtonTitles != nil) {
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
+(void)showTaggedAlertWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate tag:(NSInteger)tag cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...
{
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title
                                                     message:message
                                                    delegate:delegate
                                           cancelButtonTitle:cancelButtonTitle
                                           otherButtonTitles:otherButtonTitles, nil] autorelease];
    if (otherButtonTitles != nil) {
		va_list args;
		va_start(args, otherButtonTitles);
		NSString * title = nil;
		while((title = va_arg(args,NSString*))) {
			[alert addButtonWithTitle:title];
		}
		va_end(args);
    }
	alert.tag = tag;
    [alert show];
}






+ (void)showAlertOfSuppressedType:(NSString*)alertType
							title:(NSString *)title
						 message:(NSString *)message
						delegate:(id)delegate
			   cancelButtonTitle:(NSString *)cancelButtonTitle
			   otherButtonTitles:(NSString *)otherButtonTitles, ...
{
	BOOL isRepeat = NO;
	@synchronized(self) {
		NSMutableArray * alertTypeStrings = [[BlioAlertManager sharedInstance].suppressedAlertTypes objectForKey:alertType];
		if (alertTypeStrings) {
			if ([alertTypeStrings containsObject:message]) isRepeat = YES;
			else [alertTypeStrings addObject:message];
		}
		else {
			alertTypeStrings = [NSMutableArray arrayWithObject:message];
			[[BlioAlertManager sharedInstance].suppressedAlertTypes setObject:alertTypeStrings forKey:alertType];
		}
	}
	if (isRepeat) return;
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title
                                                     message:message
                                                    delegate:delegate
                                           cancelButtonTitle:cancelButtonTitle
                                           otherButtonTitles:otherButtonTitles, nil] autorelease];
    if (otherButtonTitles != nil) {
		va_list args;
		va_start(args, otherButtonTitles);
		NSString * title = nil;
		while((title = va_arg(args,NSString*))) {
			[alert addButtonWithTitle:title];
		}
		va_end(args);
    }
	
    [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];	
}
+(void)removeSuppressionForAlertType:(NSString*)alertType {
	[[BlioAlertManager sharedInstance].suppressedAlertTypes removeObjectForKey:alertType];
}
-(void)dealloc {
	self.suppressedAlertTypes = nil;
	[super dealloc];
}
@end
