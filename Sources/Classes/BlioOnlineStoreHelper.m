//
//  BlioOnlineStoreHelper.m
//  BlioApp
//
//  Created by Arnold Chien and Don Shin on 4/5/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import "BlioOnlineStoreHelper.h"
#import "BlioStoreManager.h"
#import "BlioAlertManager.h"
#import "BlioAppSettingsConstants.h"
#import	"Reachability.h"
#import "BlioDrmSessionManager.h"
#import "BlioBook.h"
#import "BlioVaultService.h"
#import "BlioBookInfo.h"
#import "BlioAccountService.h"

// N.B. - For other stores besides the default, BlioOnlineStoreHelper should be subclassed and the init overridden.
//#define KNFB_STORE 12151
//#define HP_STORE 12308
//#define TOSHIBA_STORE 12309
//#define DELL_STORE 12327
//#define BLIO_IPHONE_VERSION 12555

static NSString * const BlioDeletedFromArchiveAlertType = @"BlioDeletedFromArchiveAlertType";


@interface BlioOnlineStoreHelper (PRIVATE)
-(void)assessRetrieveBooksProgress;
@end
 

@implementation BlioOnlineStoreHelper

- (id) init {
	if((self = [super init])) {
		self.sourceID = BlioBookSourceOnlineStore;
		self.storeTitle = @"Blio Online Store";
		self.siteID = 12555;
		self.siteKey = @"B870B960A5B4CB53363BB10855FDC3512658E69E";
		forceLoginDisplayUponFailure = NO;
	}
	return self;
}

-(void) dealloc {
	[super dealloc];
}

-(NSString*)loginHostname {
    return [BlioAccountService sharedInstance].loginHost;
}


+(BlioTransactionType)transactionTypeForCode:(NSString*)code {
    BlioTransactionType aTransactionType = BlioTransactionTypeNotSpecified;
    if ([code isEqualToString:@"SAL"]) aTransactionType = BlioTransactionTypeSale;
    else if ([code isEqualToString:@"PRO"]) aTransactionType = BlioTransactionTypePromotion;
    else if ([code isEqualToString:@"TST"]) aTransactionType = BlioTransactionTypeTest;
    else if ([code isEqualToString:@"LND"]) aTransactionType = BlioTransactionTypeLend;
    else if ([code isEqualToString:@"FRE"]) aTransactionType = BlioTransactionTypeFree;
    else if ([code isEqualToString:@"PRE"]) aTransactionType = BlioTransactionTypePreorder;
    else if ([code isEqualToString:@"PSL"]) aTransactionType = BlioTransactionTypeSaleFromPreorder;
    return aTransactionType;
}

-(void)assessRetrieveBooksProgress {
	if (responseCount == newISBNs || newISBNs == 0) { 
		NSString * ISBNMetadataResponseAlertText = nil;
		if (successfulResponseCount == 0 && newISBNs > 0) {
			// we didn't get any successful responses, though we have a need for ISBN metadata.
			ISBNMetadataResponseAlertText = NSLocalizedStringWithDefaultValue(@"ISBN_METADATA_ALL_ATTEMPTS_FAILED",nil,[NSBundle mainBundle],@"Your latest purchases can't be retrieved at this time. Please try logging in again later.",@"Alert message when all attempts to access the ISBN meta-data web service fail.");
		}
		else if (successfulResponseCount < newISBNs) {
			// we got some successful responses, though not all for the new ISBNs.
			ISBNMetadataResponseAlertText = NSLocalizedStringWithDefaultValue(@"ISBN_METADATA_SOME_ATTEMPTS_FAILED",nil,[NSBundle mainBundle],@"Not all of your latest purchases can be retrieved at this time. Please try logging in again later.",@"Alert message when some but not all attempts to access the ISBN meta-data web service fail.");
		}
		if (ISBNMetadataResponseAlertText != nil) {
			// show alert box
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Server Error",@"\"Server Error\" alert message title")
										 message:ISBNMetadataResponseAlertText
										delegate:nil 
							   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
							   otherButtonTitles: nil];
		}
		NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
		[userInfo setObject:[NSNumber numberWithInt:self.sourceID] forKey:@"sourceID"];
		isRetrievingBooks = NO;
		[[NSNotificationCenter defaultCenter] postNotificationName:BlioStoreRetrieveBooksFinished object:self userInfo:userInfo];		 
	}
}

-(BOOL)hasValidToken {
	if (self.token == nil)
        return NO;
	if ([self.timeout compare:[NSDate date]] == NSOrderedDescending)
        return YES;
	return NO;
}
-(BlioDeviceRegisteredStatus)deviceRegistered {
	NSMutableDictionary * usersDictionary = [[[[NSUserDefaults standardUserDefaults] dictionaryForKey:kBlioUsersDictionaryDefaultsKey] mutableCopy] autorelease];
	if (usersDictionary) {
		NSMutableDictionary * currentUserDictionary = [[[usersDictionary objectForKey:[NSString stringWithFormat:@"%i",[self userNum]]] mutableCopy] autorelease];
		if (currentUserDictionary && [currentUserDictionary objectForKey:kBlioDeviceRegisteredDefaultsKey]) {
			return [[currentUserDictionary objectForKey:kBlioDeviceRegisteredDefaultsKey] intValue];
		}
	}
	return 0;
}
-(BOOL) setDeviceRegisteredSettingOnly:(BlioDeviceRegisteredStatus)targetStatus {
	NSMutableDictionary * usersDictionary = [[[[NSUserDefaults standardUserDefaults] dictionaryForKey:kBlioUsersDictionaryDefaultsKey] mutableCopy] autorelease];
	if (!usersDictionary) usersDictionary = [NSMutableDictionary dictionary];
	NSMutableDictionary * currentUserDictionary = [[[usersDictionary objectForKey:[NSString stringWithFormat:@"%i",[self userNum]]] mutableCopy] autorelease];
	if (!currentUserDictionary) currentUserDictionary = [NSMutableDictionary dictionary];				
	[currentUserDictionary setObject:[NSNumber numberWithInt:targetStatus] forKey:kBlioDeviceRegisteredDefaultsKey];
	[usersDictionary setObject:currentUserDictionary forKey:[NSString stringWithFormat:@"%i",[self userNum]]];
	[[NSUserDefaults standardUserDefaults] setObject:usersDictionary forKey:kBlioUsersDictionaryDefaultsKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
	return YES;
}
-(BOOL) setDeviceRegistered:(BlioDeviceRegisteredStatus)targetStatus {
    
    // Provisional: with KDRM there is no longer explicit registration.
    if ( targetStatus == BlioDeviceRegisteredStatusRegistered )
        return NO;
    
	if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
		NSString * internetMessage = NSLocalizedStringWithDefaultValue(@"INTERNET_REQUIRED_DEREGISTRATION",nil,[NSBundle mainBundle],@"An internet connection is required to deregister this device.",@"Alert message when the user tries to deregister the device without an Internet connection.");
		if (targetStatus == BlioDeviceRegisteredStatusRegistered) internetMessage = NSLocalizedStringWithDefaultValue(@"INTERNET_REQUIRED_DEREGISTRATION",nil,[NSBundle mainBundle],@"An internet connection is required to deregister this device.",@"Alert message when the user tries to deregister the device without an Internet connection.");
		
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Internet Connection Not Found",@"\"Internet Connection Not Found\" alert message title")
									 message:internetMessage
									delegate:nil 
						   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
						   otherButtonTitles: nil];		
		return NO;
	}
	if (![self hasValidToken]) {
		NSString * loginMessage = NSLocalizedStringWithDefaultValue(@"LOGIN_REQUIRED_DEREGISTRATION",nil,[NSBundle mainBundle],@"You must be logged in to deregister this device.",@"Alert message when the user tries to deregister the device without being logged in.");
		if (targetStatus == BlioDeviceRegisteredStatusRegistered) loginMessage = NSLocalizedStringWithDefaultValue(@"INTERNET_REQUIRED_REGISTRATION",nil,[NSBundle mainBundle],@"You must be logged in to register this device.",@"Alert message when the user tries to register the device without being logged in.");
		
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Not Logged In",@"\"Not Logged In\" alert message title")
									 message:loginMessage
									delegate:nil 
						   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
						   otherButtonTitles: nil];		
		return NO;
	}
	BlioDrmSessionManager* drmSessionManager = [[BlioDrmSessionManager alloc] initWithBookID:nil];
    if ( ![drmSessionManager leaveDomain:self.token] ) {
        // Alert shown in drmSessionManager to display error code.
        [drmSessionManager release];
        return NO;
    }
    else { 
        // de-registration succeeded, delete current user's books
        [[BlioStoreManager sharedInstance].processingDelegate deletePaidBooksForUserNum:userNum siteNum:siteID];
    }
	[drmSessionManager release];
	[self setDeviceRegisteredSettingOnly:targetStatus];
	return YES;
}

- (void)logout {
	self.token = nil;
	self.userNum = 0;
	self.timeout = [NSDate distantPast];
    [[BlioAccountService sharedInstance] logout];
    [[BlioStoreManager sharedInstance] saveToken];
}

-(void)onProductDetailsProcessingFinished:(NSNotification*)note {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioProductDetailsProcessingFinished object:nil];
    if (!_BookInfoArray || ![_BookInfoArray count]) {
        [self assessRetrieveBooksProgress];
        return;
    }
    if ( [[NSUserDefaults standardUserDefaults] integerForKey:kBlioDownloadNewBooksDefaultsKey] >= 0)
        downloadNewBooks = YES;
    else
        downloadNewBooks = NO;
    newISBNs = 0;
    NSMutableSet* incomingLoanerBooks = [NSMutableSet setWithCapacity:8];
    for (BlioBookInfo * bookInfo in _BookInfoArray) {
        // check to see if BlioBook record is already in the persistent store
        // Note:  the book identifier is now the product uuid, not the isbn or bt_key.
        BlioBook * preExistingBook = [[BlioStoreManager sharedInstance].processingDelegate bookWithSourceID:self.sourceID sourceSpecificID:bookInfo.productID];
        BlioTransactionType incomingTransactionType = bookInfo.transactionType;
        BlioTransactionType preExistingTransactionType = [[preExistingBook valueForKey:@"transactionType"] intValue];
        if (preExistingBook == nil) {
            newISBNs++;
            NSLog(@"Enqueuing new book: %@",bookInfo.productID);
            [[[BlioStoreManager sharedInstance] processingDelegate] enqueueBook:bookInfo download:downloadNewBooks];
            [self assessRetrieveBooksProgress];
        }
        /* No recordStatusId currently in Media Vault
        else if ([bookOwnershipInfo.RecordStatusId intValue] == 2) {
            [[BlioStoreManager sharedInstance].processingDelegate deleteBook:preExistingBook attemptArchive:NO shouldSave:YES];
            [BlioAlertManager showAlertOfSuppressedType:BlioDeletedFromArchiveAlertType
                                                    title:NSLocalizedString(@"Book Deleted",@"\"Book Deleted"\" alert message title")
                                                message:NSLocalizedStringWithDefaultValue(@"BOOK_DELETED",nil,[NSBundle mainBundle],@"One or more of your books have been deleted because they are no longer in your archive.",@"Alert message shown when a downloaded book has been deleted from the archive.")
                                                delegate:self
                                        cancelButtonTitle:@"OK"
                                        otherButtonTitles: nil];
        }
         */
        else if ((preExistingTransactionType == BlioTransactionTypeLend && incomingTransactionType == BlioTransactionTypePreorder) || ((preExistingTransactionType == BlioTransactionTypeLend || preExistingTransactionType == BlioTransactionTypePreorder) && (incomingTransactionType == BlioTransactionTypeSale || incomingTransactionType == BlioTransactionTypeSaleFromPreorder || incomingTransactionType == BlioTransactionTypePromotion || incomingTransactionType == BlioTransactionTypeFree))) {
            NSLog(@"replacing TransactionType:%i version of ISBN:%@ with TransactionType:%i version...",preExistingTransactionType,bookInfo.productID,incomingTransactionType);
            [[BlioStoreManager sharedInstance].processingDelegate deleteBook:preExistingBook shouldSave:YES];
            newISBNs++;
            [[[BlioStoreManager sharedInstance] processingDelegate] enqueueBook:bookInfo download:downloadNewBooks];
            [self assessRetrieveBooksProgress];

        }
        else if (incomingTransactionType == BlioTransactionTypeLend) {
            [incomingLoanerBooks addObject:bookInfo.productID];
            if  (preExistingTransactionType == BlioTransactionTypeLend) {
                NSString *dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
                NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
                [formatter setDateFormat: dateFormat];
                [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"EST"]];
                NSDate* incomingExpirationDate = bookInfo.expiration;
                // If expiration date has changed (renewal), delete book to clear way for renewed book.
                if (![incomingExpirationDate isEqualToDate:[preExistingBook valueForKey:@"expirationDate"]]) {
                    [[BlioStoreManager sharedInstance].processingDelegate deleteBook:preExistingBook attemptArchive:NO shouldSave:YES];
                    newISBNs++;
                    [[[BlioStoreManager sharedInstance] processingDelegate] enqueueBook:bookInfo download:downloadNewBooks];
                    [self assessRetrieveBooksProgress];
                    [BlioAlertManager showAlertOfSuppressedType:BlioDeletedFromArchiveAlertType
                                                            title:NSLocalizedString(@"Book Renewal",@"\"Book Renewal"\" alert message title")
                                                        message:NSLocalizedStringWithDefaultValue(@"BOOK_RENEWED",nil,[NSBundle mainBundle],@"One or more of your borrowed books have been renewed.  You can redownload them from your Archive.",@"Alert message shown when a downloaded borrowed book has been renewed.")
                                                        delegate:self
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles: nil];
                }
            }
        }
        else {
            NSLog(@"We already have book uuid: %@ in our persistent store, no need to get meta data for this item.",bookInfo.productID);
        }
    } //for
    
    /* Uncomment the below when we have borrowed books.
    // Now must see whether there are any existing loaner books that are not among the incoming loaner books.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSManagedObjectContext* moc = [[BlioBookManager sharedBookManager] managedObjectContextForCurrentThread];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"BlioBook" inManagedObjectContext:moc]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"transactionType == %@",[NSNumber numberWithInt:BlioTransactionTypeLend]]];
    NSError *errorExecute = nil;
    NSArray *results = [moc executeFetchRequest:fetchRequest error:&errorExecute];
    [fetchRequest release];
    for (BlioBook* book in results) {
        if (![incomingLoanerBooks containsObject:[book valueForKey:@"isbn"]])
            // Book has been returned, perhaps from another device.  Delete it.
            [[BlioStoreManager sharedInstance].processingDelegate deleteBook:book attemptArchive:NO shouldSave:YES];
    }
    */
    
    // TODO: why not call assessRetrieveBooksProgress unconditionally here, once, instead of after each enqueue of a new book?
    if (newISBNs == 0)
        [self assessRetrieveBooksProgress];
    
}

-(void)retrieveBooks {
	NSLog(@"**********************%@", NSStringFromSelector(_cmd));
	if (![BlioStoreManager sharedInstance].processingDelegate) {
		NSLog(@"ERROR: no processingManager set for BlioOnlineStoreHelper! Aborting retrieveBooks...");
		return;
	}
	if (![self hasValidToken]) {
		NSLog(@"ERROR: Store helper does not have a valid token! Aborting retrieveBooks...");
		return;
	}
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
	[userInfo setObject:[NSNumber numberWithInt:self.sourceID] forKey:@"sourceID"];
	isRetrievingBooks = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioStoreRetrieveBooksStarted object:self userInfo:userInfo];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProductDetailsProcessingFinished:) name:BlioProductDetailsProcessingFinished object:nil];
    if (!_session)
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];   //[BlioVaultService getProducts:_session];
    [BlioVaultService getProductsPlusDetails:_session];
    
}

-(NSURL*)URLForBookWithID:(NSString*)sourceSpecificID {
    return [BlioVaultService getDownloadURL:sourceSpecificID];
}

#pragma mark -
#pragma mark NSURLSessionDataDelegate methods

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        NSLog(@"Data task failed with error: %@", [error description]);
        return;
    }
    if (_data) {
        NSLog(@"PRODUCTS:\n%@\nEND PRODUCTS\n",
              [[NSString alloc] initWithData:_data encoding: NSUTF8StringEncoding]);
        NSError* err;
        __block id productsJSON = [NSJSONSerialization
                      JSONObjectWithData:_data
                      options:kNilOptions
                      error:&err];
        if (!productsJSON) {
            NSLog(@"Error processing JSON object from products task: %@",[err description]);
            return;
        }
        if (![productsJSON isKindOfClass:[NSArray class]]) {
            NSLog(@"Error: JSON for products list is not an array.");
            return;
        }
        if (![productsJSON count]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:BlioProductDetailsProcessingFinished object:nil];
            _data = nil;
            return;
        }
        
        void (^processProductDetails)(NSData*, NSURLResponse*, NSError*) =
            ^(NSData *data, NSURLResponse *response, NSError *error){
                NSLog(@"PRODUCT DETAILS:\n%@\nEND PRODUCT DETAILS\n",
                    [[NSString alloc] initWithData:data
                                            encoding:NSUTF8StringEncoding]);
                responseCount++;
                NSError* err;
                id productDetailsJSON = [NSJSONSerialization
                                JSONObjectWithData:data
                                options:kNilOptions
                                error:&err];
                if (!productDetailsJSON) {
                    NSLog(@"Error processing JSON object from product details task: %@",[err description]);
                    return;
                }
                if (![productDetailsJSON isKindOfClass:[NSDictionary class]]) {
                    NSLog(@"Error: JSON for product details is not a dictionary.");
                    return;
                }
                successfulResponseCount++;
                if (responseCount==1)
                    _BookInfoArray = [NSMutableArray arrayWithCapacity:8];
                NSDictionary* productDict = [_books valueForKey:[productDetailsJSON objectForKey:@"UUID"]];
                BlioBookInfo* bookInfo = [[BlioBookInfo alloc] initWithDictionary:productDict isbn:[productDetailsJSON objectForKey:@"ISBN"]];
                @synchronized(self) {
                    [_BookInfoArray addObject:bookInfo];
                }
                [bookInfo release];
                if ([_books count] == responseCount) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:BlioProductDetailsProcessingFinished object:nil];
                }
            };  // block
        
        if (_books)
            [_books release];
        _books = [[NSMutableDictionary alloc] init];
        responseCount = 0;
        successfulResponseCount = 0;
        for (int i=0;i<[productsJSON count];i++) {
            NSDictionary* productDict = [productsJSON objectAtIndex:i];
            // For now, we care only about books.  Will need to refactor.
            if ([(NSString*)[productDict valueForKey:@"ProductType"] compare:@"Book"] == NSOrderedSame) {
                // Build a hash table for use by the block.
                [_books setValue:productDict forKey:(NSString*)[productDict valueForKey:@"ProductId"]];
                NSURLSession *productIdentifiersSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue: [NSOperationQueue mainQueue]];
                // For full product details:
                //[BlioVaultService getProductDetails:productDetailsSession product:[[productsJSON objectAtIndex:i]/*[_productIDs objectAtIndex:i]*/ valueForKey:@"ProductId"] handler:processProductDetails];
                [BlioVaultService getProductIdentifiers:productIdentifiersSession product:[productDict valueForKey:@"ProductId"] handler:processProductDetails];
            }
        }
        _data = nil;
        // If doing only summary product details, uncomment the following:
        //[[NSNotificationCenter defaultCenter] postNotificationName:BlioProductDetailsProcessingFinished object:nil];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if (data) {
        if (!_data)
            _data = [[NSMutableData alloc] initWithCapacity:4096];
        [_data appendData:data];
    }
}

@end
