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

@interface BlioInAppPurchaseManager (PRIVATE) 
-(void)downloadProductWithTransaction:(SKPaymentTransaction *)transaction;
- (void) failedTransaction:(SKPaymentTransaction *)transaction;
- (void) restoreTransaction:(SKPaymentTransaction *)transaction;
- (void) completeTransaction:(SKPaymentTransaction *)transaction;
- (NSString *)encode:(const uint8_t *)input length:(NSInteger)length;
@end

@implementation BlioInAppPurchaseManager

@synthesize inAppProducts,isFetchingProducts,isRestoringTransactions;

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
-(void)restoreCompletedTransactions {
    isRestoringTransactions = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:BlioInAppPurchaseRestoreTransactionsStartedNotification object:self userInfo:nil];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

-(void)fetchProductsFromProductServer {
//	NSLog(@"%@", NSStringFromSelector(_cmd));
	if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Attention",@"\"Attention\" alert message title") 
									 message:NSLocalizedStringWithDefaultValue(@"INTERNET_REQUIRED_TO_FETCH_PRODUCTS",nil,[NSBundle mainBundle],@"An Internet connection was not found; Internet access is required to search for available in-app purchases.",@"Alert message when the user tries to fetch in-app product list without an Internet connection.")
									delegate:nil 
						   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
						   otherButtonTitles:nil];		
	}
	else {
	isFetchingProducts = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioInAppPurchaseProductsFetchStartedNotification object:self];
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
-(void)restoreProductWithID:(NSString*)anID {
    for (SKPaymentTransaction* transaction in [SKPaymentQueue defaultQueue].transactions) {
		NSString *productId = transaction.payment.productIdentifier;
		if (transaction.transactionState == SKPaymentTransactionStateRestored && [productId isEqualToString:anID]) {
            [self restoreTransaction:transaction];
            return;
        }
	}
    NSLog(@"WARNING: attempted to restore product with ID: %@, but no matching restored transaction found!",anID);
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
-(BOOL)hasPreviouslyPurchasedProductWithID:(NSString*)anID {
    for (SKPaymentTransaction* transaction in [SKPaymentQueue defaultQueue].transactions) {
		NSString *productId = transaction.payment.productIdentifier;
		if ((transaction.transactionState == SKPaymentTransactionStateRestored || transaction.transactionState == SKPaymentTransactionStatePurchased) && [productId isEqualToString:anID]) return YES;
	}
	return NO;
}

- (void) failedTransaction:(SKPaymentTransaction *)transaction
{
	NSLog(@"Transaction Failed");
	if (transaction.error.code != SKErrorPaymentCancelled)
	{
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Voice Purchase Error",@"\"Voice Purchase Error\" alert message title")
									 message:[NSString stringWithFormat:NSLocalizedString(@"An error was encountered: %@",@"Error message preface."),[transaction.error localizedDescription]]
									delegate:nil 
						   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
						   otherButtonTitles: nil];		
	}
	[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
	[userInfo setObject:transaction forKey:BlioInAppPurchaseNotificationTransactionKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioInAppPurchaseTransactionFailedNotification object:self userInfo:userInfo];
}



- (void) restoreTransaction:(SKPaymentTransaction *)transaction
{
	NSLog(@"Transaction Restoring...");
    
    NSLog(@"verify receipt for extra validation: %i",[self verifyReceipt:transaction]);
    
	NSLog(@"Transaction state: %i identifier %@",transaction.transactionState,transaction.transactionIdentifier);
    
    [self downloadProductWithTransaction:transaction];
    
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
	[userInfo setObject:transaction forKey:BlioInAppPurchaseNotificationTransactionKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioInAppPurchaseTransactionRestoredNotification object:self userInfo:userInfo];
}



- (void) completeTransaction:(SKPaymentTransaction *)transaction
{
	NSLog(@"Transaction completing...");
	NSLog(@"Transaction state: %i identifier %@",transaction.transactionState,transaction.transactionIdentifier);
	
	NSLog(@"verify receipt for extra validation: %i",[self verifyReceipt:transaction]);
	
    // DEBUG: receiptString:
    //	NSString * receiptString = [[NSString alloc] initWithData:transaction.transactionReceipt encoding:NSUTF8StringEncoding];
    //	NSLog(@"receiptString: %@", receiptString);
    //	[receiptString release];
	
    [self downloadProductWithTransaction:transaction];
    
	[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
	[userInfo setObject:transaction forKey:BlioInAppPurchaseNotificationTransactionKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioInAppPurchaseTransactionPurchasedNotification object:self userInfo:userInfo];
}

-(void)downloadProductWithTransaction:(SKPaymentTransaction *)transaction {
    NSString *productId = transaction.payment.productIdentifier;
    // get voice name from productId    
    NSString * voiceName = nil;
    for (CCInAppPurchaseProduct * product in inAppProducts) {
        if ([product.productId isEqualToString:productId]) {
            voiceName = product.name;
            break;
        }
    }
    NSArray * voiceNamesForUse = [[BlioAcapelaAudioManager sharedAcapelaAudioManager] availableVoiceNamesForUse];
    NSString *urlString = nil;
    BlioProcessingDownloadAndUnzipVoiceOperation * preExistingVoiceOp = [[BlioAcapelaAudioManager sharedAcapelaAudioManager] downloadVoiceOperationByVoice:productId];
    if (voiceName && ![voiceNamesForUse containsObject:voiceName] && !preExistingVoiceOp) {
        
        //send purchase request to our server
        NSString *hardwareId = [[UIDevice currentDevice] uniqueIdentifier];
        NSInteger testMode;
#ifdef TEST_MODE
        testMode = 1;
        NSLog(@"DOWNLOAD IN-APP TEST MODE = 1");
#else	
        testMode = 0;
        NSLog(@"DOWNLOAD IN-APP TEST MODE = 0");
#endif
        
        
        urlString = [NSString stringWithFormat:@"%@purchase?hardwareId=%@&productId=%@&testMode=%i",CCInAppPurchaseURL, hardwareId, productId,testMode];
        
    }
	
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
    
    
}

- (BOOL)verifyReceipt:(SKPaymentTransaction *)transaction {
    NSString *jsonObjectString = [self encode:(uint8_t *)transaction.transactionReceipt.bytes length:transaction.transactionReceipt.length];      
    //	NSLog(@"DEBUG: jsonObjectString: %@",jsonObjectString);
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

#pragma mark -
#pragma mark SKProductsRequestDelegate methods

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
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioInAppPurchaseProductsUpdatedNotification object:self];
}	
#pragma mark -
#pragma mark SKRequestDelegate methods

- (void)requestDidFinish:(SKRequest *)request {
	isFetchingProducts = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioInAppPurchaseProductsFetchFinishedNotification object:self];
	[request release];
}
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
	[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Voice Purchase Error",@"\"Voice Purchase Error\" alert message title")
								 message:NSLocalizedStringWithDefaultValue(@"IN_APP_PRODUCT_FETCH_FAILED",nil,[NSBundle mainBundle],@"Blio cannot retrieve available in-app products due to a server error. Please try again later.",@"Alert message when Blio cannot fetch products from the iTunes server.")
								delegate:nil 
					   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
					   otherButtonTitles: nil];		
	[request release];
	isFetchingProducts = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioInAppPurchaseProductsFetchFailedNotification object:self];
}
#pragma mark -
#pragma mark CCInAppPurchaseConnectionDelegate methods

- (void)connectionDidFinishLoading:(CCInAppPurchaseConnection *)aConnection {
	if ([aConnection.inAppPurchaseResponse isKindOfClass:[CCInAppPurchaseFetchProductsResponse class]]) {
		CCInAppPurchaseFetchProductsResponse * fetchProductsResponse = (CCInAppPurchaseFetchProductsResponse*)aConnection.inAppPurchaseResponse;
		NSLog(@"removing CCInAppPurchaseProducts that we already have installed...");
		self.inAppProducts = [NSMutableArray array];
		NSMutableArray * productIDs = [NSMutableArray array];
		NSArray * voiceNamesForUse = [[BlioAcapelaAudioManager sharedAcapelaAudioManager] availableVoiceNamesForUse];
        NSLog(@"voiceNamesForUse: %@",voiceNamesForUse);
		for (CCInAppPurchaseProduct * product in fetchProductsResponse.products) {
			if (![voiceNamesForUse containsObject:product.name]) {
				NSLog(@"adding product: %@, %@",product,product.productId);
				[inAppProducts addObject:product];
				[productIDs addObject:product.productId];
			}
		}
		
		[self requestProductsWithProductIdentifiers:[NSSet setWithArray:productIDs]];		
	}
	else if ([aConnection.inAppPurchaseResponse isKindOfClass:[CCInAppPurchasePurchaseProductResponse class]]) {
		
	}
	[aConnection release];
}
- (void)connection:(CCInAppPurchaseConnection *)aConnection didFailWithError:(NSError *)error {
	if ([aConnection.request isKindOfClass:[CCInAppPurchaseFetchProductsRequest class]]) {
		
	}
	else if ([aConnection.request isKindOfClass:[CCInAppPurchaseFetchProductsRequest class]]) {
		
	}
	[aConnection release];
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
                break;
			default:
				break;
		}
	}
}
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    isRestoringTransactions = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:BlioInAppPurchaseRestoreTransactionsFinishedNotification object:self userInfo:nil];

}
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    isRestoringTransactions = NO;
    [BlioAlertManager showAlertWithTitle:NSLocalizedString(@"iTunes Error",@"\"iTunes Error\" alert message title")
                                 message:[NSString stringWithFormat:NSLocalizedString(@"An iTunes error was encountered (%@). Please try again later",@"iTunes Restore Transactions Error message preface."),[error localizedDescription]]
                                delegate:nil 
                       cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
                       otherButtonTitles: nil];		
    [[NSNotificationCenter defaultCenter] postNotificationName:BlioInAppPurchaseRestoreTransactionsFailedNotification object:self userInfo:nil];

}

@end
