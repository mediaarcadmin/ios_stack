//Addition from http://troybrant.net/blog/2010/01/in-app-purchases-a-full-walkthrough/
// SKProduct+LocalizedPrice.h
#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface SKProduct (LocalizedPrice)

@property (nonatomic, readonly) NSString *localizedPrice;

@end