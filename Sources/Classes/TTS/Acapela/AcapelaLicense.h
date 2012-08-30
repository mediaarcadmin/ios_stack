//
//  AcapelaLicense.h
//
//  Acapela Group
//
//

#import <UIKit/UIKit.h>


@interface AcapelaLicense : NSObject {
	NSString *license;
	unsigned int user;
	unsigned int passwd;
}
@property(copy,readwrite) NSString* license;
@property(nonatomic, readwrite) unsigned int user;
@property(nonatomic, readwrite) unsigned int passwd;

- (id)initLicense:(NSString *)license user:(unsigned int)user passwd:(unsigned int)passwd;
@end
