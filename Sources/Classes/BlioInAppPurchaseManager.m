//
//  BlioInAppPurchaseManager.m
//  BlioApp
//
//  Created by Don Shin on 8/23/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import "BlioInAppPurchaseManager.h"
#import "CCInAppPurchaseService.h"
#import "BlioProcessingStandardOperations.h"
#import "BlioAcapelaAudioManager.h"
#import "BlioAlertManager.h"
#import "Reachability.h"

@implementation BlioInAppPurchaseVoice

@end

@implementation BlioInAppPurchaseManager

@synthesize inAppProducts,isFetchingProducts;

+(BlioInAppPurchaseManager*)sharedInAppPurchaseManager
{
	static BlioInAppPurchaseManager * sharedInAppPurchaseManager = nil;
	if (sharedInAppPurchaseManager == nil) {
		sharedInAppPurchaseManager = [[BlioInAppPurchaseManager alloc] init];

	}
	
	return sharedInAppPurchaseManager;
}
-(id)init {
	if ((self = [super init])) {
		[[SKPaymentQueue defaultQueue] addTransactionObserver:self];	
	}
	return self;
}
-(void)dealloc {
	[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.inAppProducts = nil;
	[super dealloc];
}
-(void)fetchProductsFromProductServer {
	NSLog(@"%@", NSStringFromSelector(_cmd));
	if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Attention",@"\"Attention\" alert message title") 
									 message:NSLocalizedStringWithDefaultValue(@"INTERNET_REQUIRED_TO_FETCH_PRODUCTS",nil,[NSBundle mainBundle],@"An Internet connection was not found; Internet access is required to search for available in-app purchases.",@"Alert message when the user tries to fetch in-app product list without an Internet connection.")
									delegate:nil 
						   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
						   otherButtonTitles:nil];		
	}
	else {
	isFetchingProducts = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioInAppPurchaseProductsFetchStarted object:self];
	CCInAppPurchaseConnection * connection = [[CCInAppPurchaseConnection alloc] initWithRequest:[[[CCInAppPurchaseFetchProductsRequest alloc] init] autorelease]];
	connection.delegate = self;
	[connection start];
	}
}
-(void)requestProductsWithProductIdentifiers:(NSSet*)aSet {
	SKProductsRequest* productRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:aSet];	
	productRequest.delegate = self;
	[productRequest start];
}

- (BOOL)canMakePurchases {
    return [SKPaymentQueue canMakePayments];
}
-(void)purchaseProductWithID:(NSString*)anID {
	NSLog(@"making payment for product with ID: %@",anID);
    SKPayment *payment = [SKPayment paymentWithProductIdentifier:anID];
    if (payment) [[SKPaymentQueue defaultQueue] addPayment:payment];	
}
-(BOOL)isPurchasingProductWithID:(NSString*)anID {
	for (SKPaymentTransaction* transaction in [SKPaymentQueue defaultQueue].transactions) {
		NSString *productId = transaction.payment.productIdentifier;
		if ([productId isEqualToString:anID] && transaction.transactionState == SKPaymentTransactionStatePurchasing) return YES;
	}
	return NO;
}
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
	NSLog(@"%@", NSStringFromSelector(_cmd));
	NSLog(@"received %i products from apple product request",[response.products count]);
	for (SKProduct* product in response.products) {
		for (CCInAppPurchaseProduct* inAppPurchaseProduct in self.inAppProducts) {
			if ([inAppPurchaseProduct.productId isEqualToString:product.productIdentifier]) {
				inAppPurchaseProduct.product = product;
			}
		}
	}
	NSLog(@"response: %@",response);
	NSLog(@"response.invalidProductIdentifiers: %@",response.invalidProductIdentifiers);
	// broadcast notification
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioInAppPurchaseProductsUpdated object:self];
}	
- (void)requestDidFinish:(SKRequest *)request {
	isFetchingProducts = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioInAppPurchaseProductsFetchFinished object:self];
	[request release];
}
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
	[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"We're Sorry...",@"\"We're Sorry...\" alert message title")
								 message:NSLocalizedStringWithDefaultValue(@"IN_APP_PRODUCT_FETCH_FAILED",nil,[NSBundle mainBundle],@"Blio cannot retrieve available in-app products due to a server error. Please try again later.",@"Alert message when Blio cannot fetch products from the iTunes server.")
								delegate:nil 
					   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
					   otherButtonTitles: nil];		
	[request release];
	isFetchingProducts = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioInAppPurchaseProductsFetchFailed object:self];
}
- (void)connectionDidFinishLoading:(CCInAppPurchaseConnection *)aConnection {
	if ([aConnection.inAppPurchaseResponse isKindOfClass:[CCInAppPurchaseFetchProductsResponse class]]) {
		CCInAppPurchaseFetchProductsResponse * fetchProductsResponse = (CCInAppPurchaseFetchProductsResponse*)aConnection.inAppPurchaseResponse;
		NSLog(@"removing CCInAppPurchaseProducts that we already have installed...");
		self.inAppProducts = [NSMutableArray array];
		NSMutableArray * productIDs = [NSMutableArray array];
		NSArray * voiceNamesForUse = [[BlioAcapelaAudioManager sharedAcapelaAudioManager] availableVoiceNamesForUse];
		for (CCInAppPurchaseProduct * product in fetchProductsResponse.products) {
			if (![voiceNamesForUse containsObject:product.name]) {
				NSLog(@"product: %@, %@",product,product.productId);
				[inAppProducts addObject:product];
				[productIDs addObject:product.productId];
			}
		}
		
		[self requestProductsWithProductIdentifiers:[NSSet setWithArray:productIDs]];		
	}
	else if ([aConnection.inAppPurchaseResponse isKindOfClass:[CCInAppPurchasePurchaseProductResponse class]]) {
		
	}
}
- (void)connection:(CCInAppPurchaseConnection *)aConnection didFailWithError:(NSError *)error {
	if ([aConnection.request isKindOfClass:[CCInAppPurchaseFetchProductsRequest class]]) {
		
	}
	else if ([aConnection.request isKindOfClass:[CCInAppPurchaseFetchProductsRequest class]]) {
		
	}
}
#pragma mark -
#pragma mark SKPaymentTransactionObserver

- (void) paymentQueue:(SKPaymentQueue *)queue
  updatedTransactions:(NSArray *)transactions
{
	for (SKPaymentTransaction *transaction in transactions)
	{
		switch (transaction.transactionState)
		{
			case SKPaymentTransactionStatePurchased:
				[self completeTransaction:transaction];
				break;
			case SKPaymentTransactionStateFailed:
				[self failedTransaction:transaction];
				break;
			case SKPaymentTransactionStateRestored:
				[self restoreTransaction:transaction];
			default:
				break;
		}
	}
}



- (void) failedTransaction:(SKPaymentTransaction *)transaction
{
	NSLog(@"Transaction Failed");
	if (transaction.error.code != SKErrorPaymentCancelled)
	{
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"We're Sorry...",@"\"We're Sorry...\" alert message title")
									 message:[NSString stringWithFormat:NSLocalizedString(@"An error was encountered: %@",@"Error message preface."),[transaction.error localizedDescription]]
									delegate:nil 
						   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
						   otherButtonTitles: nil];		
	}
	[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
	[userInfo setObject:transaction forKey:BlioInAppPurchaseNotificationTransactionKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioInAppPurchaseTransactionFailed object:self userInfo:userInfo];
}



- (void) restoreTransaction:(SKPaymentTransaction *)transaction
{
	NSLog(@"Transaction Restored");
	//If you want to save the transaction
	// [self recordTransaction: transaction];
	
	//Provide the new content
	//	[self provideContent: transaction.originalTransaction.payment.productIdentifier];
	
	//Finish the transaction
	[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
	[userInfo setObject:transaction forKey:BlioInAppPurchaseNotificationTransactionKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioInAppPurchaseTransactionRestored object:self userInfo:userInfo];
}



- (void) completeTransaction:(SKPaymentTransaction *)transaction
{
	NSLog(@"Transaction completing...");
	//If you want to save the transaction
	// [self recordTransaction:transaction];
	NSLog(@"Transaction: ",transaction);
	NSLog(@"Transaction state: %i identifier %@",transaction.transactionState,transaction.transactionIdentifier);
	
	NSLog(@"verify receipt for debugging purposes: %i",[self verifyReceipt:transaction]);
	
	NSString * receiptString = [[NSString alloc] initWithData:transaction.transactionReceipt encoding:NSUTF8StringEncoding];
	NSLog(@"receiptString: %@", receiptString);
	[receiptString release];
	
	//send purchase request to bible touch servers
	NSString *productId = transaction.payment.productIdentifier;
	NSString *hardwareId = [[UIDevice currentDevice] uniqueIdentifier];
	NSInteger testMode;
#ifdef TEST_MODE
	testMode = 1;
	NSLog(@"DOWNLOAD IN-APP TEST MODE = 1");
#else	
	testMode = 0;
	NSLog(@"DOWNLOAD IN-APP TEST MODE = 0");
#endif
	
	
	NSString *urlString = [NSString stringWithFormat:@"%@purchase?hardwareId=%@&productId=%@&testMode=%i",CCInAppPurchaseURL, hardwareId, productId,testMode];

//	CCInAppPurchasePurchaseProductRequest * request = [[CCInAppPurchasePurchaseProductRequest alloc] initWithProductID:productId hardwareID:hardwareId];
//	request.HTTPBody = postData;
//	CCInAppPurchaseConnection * connection = [[CCInAppPurchaseConnection alloc] initWithRequest:request];
//	[request release];
//	connection.delegate = self;
//	[connection start];
	
	if (urlString) {
		BlioProcessingDownloadAndUnzipVoiceOperation * voiceOperation = [[BlioProcessingDownloadAndUnzipVoiceOperation alloc] initWithUrl:[NSURL URLWithString:urlString]];
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
		NSString *docsPath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
		voiceOperation.tempDirectory = docsPath;
		NSArray *paths2 = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
		NSString *docsPath2 = ([paths2 count] > 0) ? [paths2 objectAtIndex:0] : nil;
		voiceOperation.cacheDirectory = docsPath2;
		voiceOperation.filenameKey = productId;
		voiceOperation.voice = productId;
		voiceOperation.resume = NO;
//		voiceOperation.requestHTTPBody = transaction.transactionReceipt;
		voiceOperation.requestHTTPBody = [[self encode:(uint8_t *)transaction.transactionReceipt.bytes length:transaction.transactionReceipt.length] dataUsingEncoding:NSUTF8StringEncoding];
		
		NSLog(@"adding BlioProcessingDownloadAndUnzipVoiceOperation to queue...");
		[[BlioAcapelaAudioManager sharedAcapelaAudioManager].downloadQueue addOperation:voiceOperation];
		[voiceOperation release];
	}
	[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
	[userInfo setObject:transaction forKey:BlioInAppPurchaseNotificationTransactionKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioInAppPurchaseTransactionPurchased object:self userInfo:userInfo];
}

- (BOOL)verifyReceipt:(SKPaymentTransaction *)transaction {
    NSString *jsonObjectString = [self encode:(uint8_t *)transaction.transactionReceipt.bytes length:transaction.transactionReceipt.length];      
	NSLog(@"jsonObjectString: %@",jsonObjectString);
	NSString *completeString = [NSString stringWithFormat:@"http://url-for-your-php?receipt=%@", jsonObjectString];                               
    NSURL *urlForValidation = [NSURL URLWithString:completeString];               
    NSMutableURLRequest *validationRequest = [[NSMutableURLRequest alloc] initWithURL:urlForValidation];                          
    [validationRequest setHTTPMethod:@"GET"];             
    NSData *responseData = [NSURLConnection sendSynchronousRequest:validationRequest returningResponse:nil error:nil];  
    [validationRequest release];
    NSString *responseString = [[NSString alloc] initWithData:responseData encoding: NSUTF8StringEncoding];
    NSInteger response = [responseString integerValue];
    [responseString release];
    return (response == 0);
}

- (NSString *)encode:(const uint8_t *)input length:(NSInteger)length {
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
	
    NSMutableData *data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t *output = (uint8_t *)data.mutableBytes;
	
    for (NSInteger i = 0; i < length; i += 3) {
        NSInteger value = 0;
        for (NSInteger j = i; j < (i + 3); j++) {
			value <<= 8;
			
			if (j < length) {
				value |= (0xFF & input[j]);
			}
        }
		
        NSInteger index = (i / 3) * 4;
        output[index + 0] =                    table[(value >> 18) & 0x3F];
        output[index + 1] =                    table[(value >> 12) & 0x3F];
        output[index + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[index + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
	
    return [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
}

@end
