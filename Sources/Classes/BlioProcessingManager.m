//
//  BlioProcessingManager.m
//  BlioApp
//
//  Created by matt on 24/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioProcessingManager.h"
#import "BlioProcessingStandardOperations.h"
#import "BlioFlowView.h"

@interface BlioProcessingManager()
@property (nonatomic, retain) NSOperationQueue *preAvailabilityQueue;
@property (nonatomic, retain) NSOperationQueue *postAvailabilityQueue;
@end

@implementation BlioProcessingManager

@synthesize managedObjectContext, preAvailabilityQueue, postAvailabilityQueue;

- (void)dealloc {
    [self.preAvailabilityQueue cancelAllOperations];
    [self.postAvailabilityQueue cancelAllOperations];
    self.preAvailabilityQueue = nil;
    self.postAvailabilityQueue = nil;
    self.managedObjectContext = nil;
    [super dealloc];
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aManagedObjectContext {
    if ((self = [super init])) {
        self.managedObjectContext = aManagedObjectContext;
        
        NSOperationQueue *aPreAvailabilityQueue = [[NSOperationQueue alloc] init];
        self.preAvailabilityQueue = aPreAvailabilityQueue;
        [aPreAvailabilityQueue release];
        
        NSOperationQueue *aPostAvailabilityQueue = [[NSOperationQueue alloc] init];
        self.postAvailabilityQueue = aPostAvailabilityQueue;
        [aPostAvailabilityQueue release];
    }
    return self;
}

#pragma mark -
#pragma mark BlioProcessingDelegate
- (void)enqueueBookWithTitle:(NSString *)title authors:(NSArray *)authors coverURL:(NSURL *)coverURL 
                     ePubURL:(NSURL *)ePubURL pdfURL:(NSURL *)pdfURL textFlowURL:(NSURL *)textFlowURL 
                audiobookURL:(NSURL *)audiobookURL {
	// for legacy compatibility (pre-sourceID and sourceSpecificID)
	[self enqueueBookWithTitle:title authors:authors coverURL:coverURL 
					   ePubURL:ePubURL pdfURL:pdfURL textFlowURL:textFlowURL 
				  audiobookURL:audiobookURL sourceID:@"" sourceSpecificID:title];
}
- (void)enqueueBookWithTitle:(NSString *)title authors:(NSArray *)authors coverURL:(NSURL *)coverURL 
                     ePubURL:(NSURL *)ePubURL pdfURL:(NSURL *)pdfURL textFlowURL:(NSURL *)textFlowURL 
                audiobookURL:(NSURL *)audiobookURL sourceID:(NSString*)sourceID sourceSpecificID:(NSString*)sourceSpecificID {    
    NSManagedObjectContext *moc = self.managedObjectContext;
    if (nil != moc) {
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:[NSEntityDescription entityForName:@"BlioMockBook" inManagedObjectContext:moc]];        
        
        NSError *error;
        BlioMockBook *aBook = nil;
        
        NSUInteger count = [moc countForFetchRequest:request error:&error];
        [request release];
        if (count == NSNotFound) {
            NSLog(@"Failed to retrieve book count with error: %@, %@", error, [error userInfo]);
            return;
        } 
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[NSEntityDescription entityForName:@"BlioMockBook" inManagedObjectContext:moc]];
		//	NSLog(@"sourceSpecificID: %@",[self.entity id]);
		//	NSLog(@"sourceID: %@",[self.feed id]);
		[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"sourceSpecificID == %@ && sourceID == %@", sourceSpecificID,sourceID]];
		
		NSError *errorExecute = nil; 
		NSArray *results = [moc executeFetchRequest:fetchRequest error:&errorExecute]; 
		[fetchRequest release];
		
		if (errorExecute) {
			NSLog(@"Error getting executeFetchRequest results. %@, %@", errorExecute, [errorExecute userInfo]);
			return;
		}
		if ([results count] > 1) {
			NSLog(@"WARNING: More than one book found with sourceSpecificID:%@ and sourceID:%@",sourceSpecificID,sourceID); 
		} else if ([results count] == 1) {

			NSLog(@"Processing Manager: Found Book in context already"); 
			
			aBook = [results objectAtIndex:0];
			
			
			if ([[aBook valueForKey:@"processingComplete"] isEqualToNumber: [NSNumber numberWithInt:kBlioMockBookProcessingStateComplete]]) {
				NSLog(@"WARNING: enqueue method called on already complete book with sourceSpecificID:%@ and sourceID:%@",sourceSpecificID,sourceID);
				NSLog(@"Aborting enqueue by prematurely returning...");
				return;
			}
		} else {
			// create a new book in context from scratch
//			NSLog(@"Processing Manager: Creating new book"); 
            aBook = [NSEntityDescription insertNewObjectForEntityForName:@"BlioMockBook" inManagedObjectContext:moc];
		}
		
        [aBook setValue:title forKey:@"title"];
        [aBook setValue:sourceID forKey:@"sourceID"];
        [aBook setValue:sourceSpecificID forKey:@"sourceSpecificID"];
        [aBook setValue:[authors lastObject] forKey:@"author"];
        [aBook setValue:[NSNumber numberWithInt:count] forKey:@"position"];        
        [aBook setValue:[NSNumber numberWithInt:kBlioMockBookProcessingStateIncomplete] forKey:@"processingComplete"];
		
		if (coverURL != nil) [aBook setValue:[coverURL absoluteString] forKey:@"coverFilename"];
		if (ePubURL != nil) [aBook setValue:[ePubURL absoluteString] forKey:@"epubFilename"];
		if (pdfURL != nil) [aBook setValue:[pdfURL absoluteString] forKey:@"pdfFilename"];
		if (textFlowURL != nil) [aBook setValue:[textFlowURL absoluteString] forKey:@"textFlowFilename"];
		if (audiobookURL != nil) [aBook setValue:[audiobookURL absoluteString] forKey:@"audiobookFilename"];
		
		if ([aBook valueForKey:@"uuid"] == nil)
		{
			// generate uuid
			CFUUIDRef theUUID = CFUUIDCreate(NULL);
			CFStringRef uniqueString = CFUUIDCreateString(NULL, theUUID);
			CFRelease(theUUID);
			[aBook setValue:(NSString *)uniqueString forKey:@"uuid"];
			CFRelease(uniqueString);
		}        
        if (![moc save:&error]) {
            NSLog(@"Save failed in processing manager with error: %@, %@", error, [error userInfo]);
        }
		[self enqueueBook:aBook];
	}
}
-(void) enqueueBook:(BlioMockBook*)aBook {
//	NSLog(@"BlioProcessingManager enqueueBook: %@",aBook);
	// NOTE: we're making the assumption that the processing manager is using the same MOC as the LibraryView!!!
    NSManagedObjectContext *moc = self.managedObjectContext;
    if (moc == nil) {
		NSLog(@"WARNING: enqueueing book attempted while Processing Manager MOC == nil!");
		return;
	}
	else {

		NSManagedObjectID *bookID = [aBook objectID];
		NSString *cacheDir = [aBook bookCacheDirectory];
		NSString *tempDir = [aBook bookTempDirectory];
		NSString *sourceID = [aBook sourceID];
		NSString *sourceSpecificID = [aBook sourceSpecificID];
		
		if ([[aBook valueForKey:@"processingComplete"] isEqualToNumber: [NSNumber numberWithInt:kBlioMockBookProcessingStateComplete]]) {
			NSLog(@"WARNING: enqueue method called on already complete book!");
			NSLog(@"Aborting enqueue by prematurely returning...");
			return;
		}
		if ([[aBook valueForKey:@"processingComplete"] isEqualToNumber: [NSNumber numberWithInt:kBlioMockBookProcessingStateIncomplete]]) {
			// status is incomplete; operations involved with this book may or may not be in the queue, so we'll cancel the CompleteOperation for this book if it exists and co-opt the other operations if they haven't been cancelled yet
			BlioProcessingOperation * oldCompleteOperation = [self processingCompleteOperationForSourceID: sourceID sourceSpecificID:sourceSpecificID];
			if (oldCompleteOperation) [oldCompleteOperation cancel];
		}

		NSError * error;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:&error])
			NSLog(@"Failed to create book cache directory in processing manager with error: %@, %@", error, [error userInfo]);
		
		NSMutableArray *bookOps = [NSMutableArray array];

		NSURL * url = nil;
		NSString * stringURL = nil;
		NSUInteger alreadyCompletedOperations = 0;
		
		stringURL = [aBook valueForKey:@"coverFilename"];
		if (stringURL) {
			if ([stringURL rangeOfString:@"://"].location != NSNotFound) url = [NSURL URLWithString:stringURL];
			else {
				url = nil;
				alreadyCompletedOperations++;
			}
			if (url != nil) {
				BlioProcessingDownloadCoverOperation *coverOp = [[BlioProcessingDownloadCoverOperation alloc] initWithUrl:url];
				coverOp.bookID = bookID;
				coverOp.sourceID = sourceID;
				coverOp.sourceSpecificID = sourceSpecificID;
				coverOp.localFilename = [aBook valueForKey:coverOp.filenameKey];
				coverOp.storeCoordinator = [moc persistentStoreCoordinator];
				coverOp.cacheDirectory = cacheDir;
				coverOp.tempDirectory = tempDir;
				[coverOp setQueuePriority:NSOperationQueuePriorityHigh];
				[self.preAvailabilityQueue addOperation:coverOp];
				[bookOps addObject:coverOp];
				
				BlioProcessingGenerateCoverThumbsOperation *thumbsOp = [[BlioProcessingGenerateCoverThumbsOperation alloc] init];
				thumbsOp.bookID = bookID;
				thumbsOp.sourceID = sourceID;
				thumbsOp.sourceSpecificID = sourceSpecificID;
				thumbsOp.storeCoordinator = [moc persistentStoreCoordinator];
				thumbsOp.cacheDirectory = cacheDir;
				thumbsOp.tempDirectory = tempDir;
				[thumbsOp addDependency:coverOp];
				[thumbsOp setQueuePriority:NSOperationQueuePriorityVeryHigh];
				[self.preAvailabilityQueue addOperation:thumbsOp];
				[bookOps addObject:thumbsOp];
				
				[coverOp release];
				[thumbsOp release];
			}
		}
		stringURL = [aBook valueForKey:@"epubFilename"];
		if (stringURL && nil == [aBook valueForKey:@"textFlowFilename"]) {
			if ([stringURL rangeOfString:@"://"].location != NSNotFound) url = [NSURL URLWithString:stringURL];
			else {
				alreadyCompletedOperations++;
				url = nil;
			}
			BOOL usedPreExistingOperation = NO;
			BlioProcessingDownloadEPubOperation * ePubOp = nil;
			if (nil != url) {
				// we still need to finish downloading this file
				// so check to see if operation already exists
				ePubOp = (BlioProcessingDownloadEPubOperation*)[self operationByClass:NSClassFromString(@"BlioProcessingDownloadEPubOperation") forSourceID:sourceID sourceSpecificID:sourceSpecificID];

				if (!ePubOp || ePubOp.isCancelled) // TODO: honor force reprocess option here
				{
					ePubOp = [[[BlioProcessingDownloadEPubOperation alloc] initWithUrl:url] autorelease];
					ePubOp.bookID = bookID;
					ePubOp.sourceID = sourceID;
					ePubOp.sourceSpecificID = sourceSpecificID;
					ePubOp.localFilename = [aBook valueForKey:ePubOp.filenameKey];
					ePubOp.storeCoordinator = [moc persistentStoreCoordinator];
					ePubOp.cacheDirectory = cacheDir;
					ePubOp.tempDirectory = tempDir;
					[self.preAvailabilityQueue addOperation:ePubOp];
				}
				else {
					// we reuse existing one
					usedPreExistingOperation = YES;
				}
				[bookOps addObject:ePubOp];
			}
			NSArray *ePubPreAvailOps = [BlioFlowView preAvailabilityOperations];
			for (BlioProcessingOperation *preAvailOp in ePubPreAvailOps) {
				BlioProcessingOperation * preExist = [self operationByClass:[preAvailOp class] forSourceID:sourceID sourceSpecificID:sourceSpecificID];
				if (!preExist || preExist.isCancelled) {
					preAvailOp.bookID = bookID;
					preAvailOp.sourceID = sourceID;
					preAvailOp.sourceSpecificID = sourceSpecificID;
					preAvailOp.storeCoordinator = [moc persistentStoreCoordinator];
					preAvailOp.cacheDirectory = cacheDir;
					preAvailOp.tempDirectory = tempDir;
					if (ePubOp && usedPreExistingOperation == NO) [preAvailOp addDependency:ePubOp];
					[self.preAvailabilityQueue addOperation:preAvailOp];
					[bookOps addObject:preAvailOp];
				}
				else {
					// if it already exists, it is dependent on a completed operation
					[bookOps addObject:preExist];
				}
				
			}                    
		}
		stringURL = [aBook valueForKey:@"pdfFilename"];
		if (stringURL) {
			if ([stringURL rangeOfString:@"://"].location != NSNotFound) url = [NSURL URLWithString:stringURL];
			else {
				alreadyCompletedOperations++;
				url = nil;
			}
			BOOL usedPreExistingOperation = NO;
			BlioProcessingDownloadPdfOperation * pdfOp = nil;

			if (nil != url) {
				// we still need to finish downloading this file
				// so check to see if operation already exists
				pdfOp = (BlioProcessingDownloadPdfOperation*)[self operationByClass:NSClassFromString(@"BlioProcessingDownloadPdfOperation") forSourceID:sourceID sourceSpecificID:sourceSpecificID];

				if (!pdfOp || pdfOp.isCancelled) {

					pdfOp = [[[BlioProcessingDownloadPdfOperation alloc] initWithUrl:url] autorelease];
					pdfOp.bookID = bookID;
					pdfOp.sourceID = sourceID;
					pdfOp.sourceSpecificID = sourceSpecificID;
					pdfOp.localFilename = [aBook valueForKey:pdfOp.filenameKey];
					pdfOp.storeCoordinator = [moc persistentStoreCoordinator];
					pdfOp.cacheDirectory = cacheDir;
					pdfOp.tempDirectory = tempDir;
					[self.preAvailabilityQueue addOperation:pdfOp];
				}
				else {
					usedPreExistingOperation = YES; // in case we have dependent operations in the future
				}
				[bookOps addObject:pdfOp];
			}
		}

		stringURL = [aBook valueForKey:@"textFlowFilename"];
		if (stringURL) {
			if ([stringURL rangeOfString:@"://"].location != NSNotFound) url = [NSURL URLWithString:stringURL];
			else {
				alreadyCompletedOperations++;
				url = nil;
			}
			BOOL usedPreExistingOperation = NO;
			BlioProcessingDownloadTextFlowOperation * textFlowOp = nil;

			if (nil != url) {
				// we still need to finish downloading this file
				// so check to see if operation already exists
				textFlowOp = (BlioProcessingDownloadTextFlowOperation*)[self operationByClass:NSClassFromString(@"BlioProcessingDownloadTextFlowOperation") forSourceID:sourceID sourceSpecificID:sourceSpecificID];
				if (!textFlowOp || textFlowOp.isCancelled) {
					textFlowOp = [[[BlioProcessingDownloadTextFlowOperation alloc] initWithUrl:url] autorelease];
					textFlowOp.bookID = bookID; 
					textFlowOp.sourceID = sourceID;
					textFlowOp.sourceSpecificID = sourceSpecificID;
					textFlowOp.localFilename = [aBook valueForKey:textFlowOp.filenameKey];
					textFlowOp.storeCoordinator = [moc persistentStoreCoordinator];
					textFlowOp.cacheDirectory = cacheDir;
					textFlowOp.tempDirectory = tempDir;
					[self.preAvailabilityQueue addOperation:textFlowOp];
				}
				else {
					// we reuse existing one
					usedPreExistingOperation = YES;
				}
				[bookOps addObject:textFlowOp];
			}
			NSArray *textFlowPreAvailOps = [BlioTextFlow preAvailabilityOperations];
			NSMutableArray * newTextFlowPreAvailOps = [NSMutableArray array];
			for (BlioProcessingOperation *preAvailOp in textFlowPreAvailOps) {
				BlioProcessingOperation * preExist = [self operationByClass:[preAvailOp class] forSourceID:sourceID sourceSpecificID:sourceSpecificID];
				if (!preExist || preExist.isCancelled) {
					
					preAvailOp.bookID = bookID;
					preAvailOp.sourceID = sourceID;
					preAvailOp.sourceSpecificID = sourceSpecificID;
					preAvailOp.storeCoordinator = [moc persistentStoreCoordinator];
					preAvailOp.cacheDirectory = cacheDir;
					preAvailOp.tempDirectory = tempDir;
					if (textFlowOp) [preAvailOp addDependency:textFlowOp];
					[self.preAvailabilityQueue addOperation:preAvailOp];
					[bookOps addObject:preAvailOp];
					[newTextFlowPreAvailOps addObject:preAvailOp];
				}
				else {
					// if it already exists, it is dependent on a completed operation
					[bookOps addObject:preExist];
					[newTextFlowPreAvailOps addObject:preExist];
				}
			}
			
			NSArray *flowViewPreAvailOps = [BlioFlowView preAvailabilityOperations];
			for (BlioProcessingOperation *preAvailOp in flowViewPreAvailOps) {
				BlioProcessingOperation * preExist = [self operationByClass:[preAvailOp class] forSourceID:sourceID sourceSpecificID:sourceSpecificID];
				if (!preExist || preExist.isCancelled) {
					preAvailOp.bookID = bookID;
					preAvailOp.storeCoordinator = [moc persistentStoreCoordinator];
					preAvailOp.cacheDirectory = cacheDir;
					preAvailOp.tempDirectory = tempDir;
					for(BlioProcessingOperation *beforeOp in newTextFlowPreAvailOps) {
						[preAvailOp addDependency:beforeOp];
					}
					[self.preAvailabilityQueue addOperation:preAvailOp];
					[bookOps addObject:preAvailOp];
				}
				else {
					// if it already exists, it is dependent on a completed operation
					[bookOps addObject:preExist];
				}				
			}                    			
		}
		stringURL = [aBook valueForKey:@"audiobookFilename"];
		if (stringURL) {

			if ([stringURL rangeOfString:@"://"].location != NSNotFound) url = [NSURL URLWithString:stringURL];
			else {
				alreadyCompletedOperations++;
				url = nil;
			}
			BOOL usedPreExistingOperation = NO;
			BlioProcessingDownloadAudiobookOperation * audiobookOp = nil;
			
			if (nil != url) {
				// we still need to finish downloading this file
				// so check to see if operation already exists
				audiobookOp = (BlioProcessingDownloadAudiobookOperation*)[self operationByClass:NSClassFromString(@"BlioProcessingDownloadAudiobookOperation") forSourceID:sourceID sourceSpecificID:sourceSpecificID];
				if (!audiobookOp || audiobookOp.isCancelled) {
					audiobookOp = [[[BlioProcessingDownloadAudiobookOperation alloc] initWithUrl:url] autorelease];
					audiobookOp.bookID = bookID;
					audiobookOp.sourceID = sourceID;
					audiobookOp.sourceSpecificID = sourceSpecificID;
					audiobookOp.localFilename = [aBook valueForKey:audiobookOp.filenameKey];
					audiobookOp.storeCoordinator = [moc persistentStoreCoordinator];
					audiobookOp.cacheDirectory = cacheDir;
					audiobookOp.tempDirectory = tempDir;
					[self.preAvailabilityQueue addOperation:audiobookOp];
				}
				else {
					// we reuse existing one
					usedPreExistingOperation = YES;
				}
				[bookOps addObject:audiobookOp];
			}
		}
		
		BlioProcessingCompleteOperation *completeOp = [[BlioProcessingCompleteOperation alloc] init];
		[completeOp setQueuePriority:NSOperationQueuePriorityVeryHigh];
		completeOp.alreadyCompletedOperations = alreadyCompletedOperations;
		completeOp.bookID = bookID;
		completeOp.sourceID = sourceID;
		completeOp.sourceSpecificID = sourceSpecificID;
		completeOp.storeCoordinator = [moc persistentStoreCoordinator];
		completeOp.cacheDirectory = cacheDir;
		completeOp.tempDirectory = tempDir;

		
		for (NSOperation *op in bookOps) {
			[completeOp addDependency:op];
		}
		
		[self.preAvailabilityQueue addOperation:completeOp];
		[completeOp release];
		
		// now that completeOp is in queue, we change the model (which in turn triggers a refresh in LibraryView; the gridcell can successfully find the completeOp in the queue and become a listener to it.
		if ([[aBook valueForKey:@"processingComplete"] isEqualToNumber: [NSNumber numberWithInt:kBlioMockBookProcessingStatePaused]]) {
			// if book is paused, reflect unpausing in state
			[aBook setValue:[NSNumber numberWithInt:kBlioMockBookProcessingStateIncomplete] forKey:@"processingComplete"];			
			NSError * error;
			if (![moc save:&error]) {
				NSLog(@"Save failed in processing manager with error: %@, %@", error, [error userInfo]);
			}			
		}		
	}
}
- (void)pauseProcessingForBook:(BlioMockBook*)aBook {
	NSLog(@"BlioProcessingManager pauseProcessingForBook entered");
    NSManagedObjectContext *moc = self.managedObjectContext;
    if (moc == nil) {
		NSLog(@"WARNING: pause processing attempted while Processing Manager MOC == nil!");
		return;
	}
    [aBook setValue:[NSNumber numberWithInt:kBlioMockBookProcessingStatePaused] forKey:@"processingComplete"];
	[self stopProcessingForBook:aBook];
	NSError * error;
	if (![moc save:&error]) {
		NSLog(@"Save failed in processing manager with error: %@, %@", error, [error userInfo]);
	}			
}
- (void)stopProcessingForBook:(BlioMockBook*)aBook {
    NSManagedObjectContext *moc = self.managedObjectContext;
    if (moc == nil) {
		NSLog(@"WARNING: stop processing for book attempted while Processing Manager MOC == nil!");
		return;
	}
	[[self processingCompleteOperationForSourceID:aBook.sourceID sourceSpecificID:aBook.sourceSpecificID] cancel];
	
	NSArray * relatedOperations = [self processingOperationsForSourceID:aBook.sourceID sourceSpecificID:aBook.sourceSpecificID];
	for (BlioProcessingOperation * op in relatedOperations) {
		[op cancel];
	}
}
-(void) deleteBook:(BlioMockBook*)aBook shouldSave:(BOOL)shouldSave {
	// if book is processing, stop all associated operations
	if ([[aBook valueForKey:@"processingComplete"] intValue] == kBlioMockBookProcessingStateIncomplete) [self stopProcessingForBook:aBook];
	
    NSManagedObjectContext *moc = self.managedObjectContext;
	NSError * error;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	// delete temporary files (which are only present if processing is not complete)
	if ([fileManager fileExistsAtPath:[aBook bookTempDirectory]]) {
		if (![fileManager removeItemAtPath:[aBook bookTempDirectory] error:&error]) {
			NSLog(@"WARNING: deletion of temporary directory for book failed. %@, %@", error, [error userInfo]);
		}
	}
	// delete permanent files
	if (![fileManager removeItemAtPath:[aBook bookCacheDirectory] error:&error]) {
		NSLog(@"WARNING: deletion of cache directory for book failed. %@, %@", error, [error userInfo]);
	}
	
	// delete record
	[moc deleteObject:aBook];
	if (shouldSave) {
		NSError * error;
		if (![moc save:&error]) {
			NSLog(@"deleteBook failed in processing manager with error: %@, %@", error, [error userInfo]);
		}		
	}
}
- (void)stopDownloadingOperations {
	NSArray * downloadOperations = [self downloadOperations];
	for (BlioProcessingOperation * op in downloadOperations) {
		[op cancel];
	}
	// any processing operations that are dependent on these downloads will also cancel (as intended).
}
- (BlioProcessingOperation *)processingCompleteOperationForSourceID:(NSString*)sourceID sourceSpecificID:(NSString*)sourceSpecificID {
	NSArray * operations = [preAvailabilityQueue operations];
	for (BlioProcessingOperation * op in operations) {
		if ([op isKindOfClass:[BlioProcessingCompleteOperation class]] && [sourceID isEqualToString:op.sourceID] && [sourceSpecificID isEqualToString:op.sourceSpecificID]) {
			return op;
		}
	}
	return nil;
}
- (NSArray *)processingOperationsForSourceID:(NSString*)sourceID sourceSpecificID:(NSString*)sourceSpecificID {
	NSArray * operations = [preAvailabilityQueue operations];
	NSMutableArray * tempArray = [NSMutableArray array];
	for (BlioProcessingOperation * op in operations) {
		if ([sourceID isEqualToString:op.sourceID] && [sourceSpecificID isEqualToString:op.sourceSpecificID]) {
			[tempArray addObject:op];
		}
	}
	return tempArray;
}
- (BlioProcessingOperation*) operationByClass:(Class)targetClass forSourceID:(NSString*)sourceID sourceSpecificID:(NSString*)sourceSpecificID {
	// helper function to search for such an operation that meets the conditions in the parameters
	NSArray * operations = [preAvailabilityQueue operations];
	for (BlioProcessingOperation * op in operations) {
		if ([op isKindOfClass:targetClass] && op.sourceID == sourceID && op.sourceSpecificID == sourceSpecificID) {
			return op;
		}
	}
	return nil;
	
}
- (NSArray *)downloadOperations {
	NSArray * operations = [preAvailabilityQueue operations];
	NSMutableArray * tempArray = [NSMutableArray array];
	for (BlioProcessingOperation * op in operations) {
		if ([op isKindOfClass:[BlioProcessingDownloadOperation class]]) {
			[tempArray addObject:op];
		}
	}
	return tempArray;
}

@end