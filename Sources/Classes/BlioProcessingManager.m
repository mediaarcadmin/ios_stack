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
        BlioMockBook *aBook;
        
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
			
			
			if ([aBook valueForKey:@"processingComplete"] == [NSNumber numberWithInt:kBlioMockBookProcessingStateComplete]) {
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
	// NOTE: we're making the assumption that the processing manager is using the same MOC as the LibraryView!!!
    NSManagedObjectContext *moc = self.managedObjectContext;
    if (moc == nil) {
		NSLog(@"WARNING: enqueueing book attempted while Processing Manager MOC == nil!");
		return;
	}
	else {

		if ([aBook valueForKey:@"processingComplete"] == [NSNumber numberWithInt:kBlioMockBookProcessingStateComplete]) {
			NSLog(@"WARNING: enqueue method called on already complete book!");
			NSLog(@"Aborting enqueue by prematurely returning...");
			return;
		}
		else if ([aBook valueForKey:@"processingComplete"] == [NSNumber numberWithInt:kBlioMockBookProcessingStatePaused]) {
			// if book is paused, reflect unpausing in state
			[aBook setValue:[NSNumber numberWithInt:kBlioMockBookProcessingStateIncomplete] forKey:@"processingComplete"];			
			NSError * error;
			if (![moc save:&error]) {
				NSLog(@"Save failed in processing manager with error: %@, %@", error, [error userInfo]);
			}			
		}
		

		NSManagedObjectID *bookID = [aBook objectID];
		NSString *cacheDir = [aBook bookCacheDirectory];
		NSString *tempDir = [aBook bookTempDirectory];
		NSString *sourceID = [aBook sourceID];
		NSString *sourceSpecificID = [aBook sourceSpecificID];
		NSError * error;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:&error])
			NSLog(@"Failed to create book cache directory in processing manager with error: %@, %@", error, [error userInfo]);
		
		NSMutableArray *bookOps = [NSMutableArray array];

		NSURL * url = nil;
		NSString * stringURL = nil;
		
		stringURL = [aBook valueForKey:@"coverFilename"];
		if (stringURL != nil && [stringURL rangeOfString:@"://"].location != NSNotFound) url = [NSURL URLWithString:stringURL];
		else url = nil;
		// if (stringURL != nil) NSLog(@"coverFilename: %@",stringURL);
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
		
		stringURL = [aBook valueForKey:@"epubFilename"];
		if (stringURL != nil && [stringURL rangeOfString:@"://"].location != NSNotFound) url = [NSURL URLWithString:stringURL];
		else url = nil;
		// if (stringURL != nil) NSLog(@"epubFilename: %@",stringURL);

		if (nil != url && nil == [aBook valueForKey:@"textFlowFilename"]) {

			BlioProcessingDownloadEPubOperation *ePubOp = [[BlioProcessingDownloadEPubOperation alloc] initWithUrl:url];
			ePubOp.bookID = bookID;
			ePubOp.sourceID = sourceID;
			ePubOp.sourceSpecificID = sourceSpecificID;
			ePubOp.localFilename = [aBook valueForKey:ePubOp.filenameKey];
			ePubOp.storeCoordinator = [moc persistentStoreCoordinator];
			ePubOp.cacheDirectory = cacheDir;
			ePubOp.tempDirectory = tempDir;
			[self.preAvailabilityQueue addOperation:ePubOp];
			[bookOps addObject:ePubOp];
			[ePubOp release];
			
			NSArray *ePubPreAvailOps = [BlioFlowView preAvailabilityOperations];
			for (BlioProcessingOperation *preAvailOp in ePubPreAvailOps) {
				preAvailOp.bookID = bookID;
				preAvailOp.sourceID = sourceID;
				preAvailOp.sourceSpecificID = sourceSpecificID;
				preAvailOp.storeCoordinator = [moc persistentStoreCoordinator];
				preAvailOp.cacheDirectory = cacheDir;
				preAvailOp.tempDirectory = tempDir;
				[preAvailOp addDependency:ePubOp];
				[self.preAvailabilityQueue addOperation:preAvailOp];
				[bookOps addObject:preAvailOp];
			}                    
		}
		
		stringURL = [aBook valueForKey:@"pdfFilename"];
		if (stringURL != nil && [stringURL rangeOfString:@"://"].location != NSNotFound) url = [NSURL URLWithString:stringURL];
		else url = nil;

		if (nil != url) {
			BlioProcessingDownloadPdfOperation *pdfOp = [[BlioProcessingDownloadPdfOperation alloc] initWithUrl:url];
			pdfOp.bookID = bookID;
			pdfOp.sourceID = sourceID;
			pdfOp.sourceSpecificID = sourceSpecificID;
			pdfOp.localFilename = [aBook valueForKey:pdfOp.filenameKey];
			pdfOp.storeCoordinator = [moc persistentStoreCoordinator];
			pdfOp.cacheDirectory = cacheDir;
			pdfOp.tempDirectory = tempDir;
			[self.preAvailabilityQueue addOperation:pdfOp];
			[bookOps addObject:pdfOp];
			[pdfOp release];
		}

		stringURL = [aBook valueForKey:@"textFlowFilename"];
		if (stringURL != nil && [stringURL rangeOfString:@"://"].location != NSNotFound) url = [NSURL URLWithString:stringURL];
		else url = nil;
		// if (stringURL != nil) NSLog(@"textFlowFilename: %@",stringURL);

		if (nil != url) {
			BlioProcessingDownloadTextFlowOperation *textFlowOp = [[BlioProcessingDownloadTextFlowOperation alloc] initWithUrl:url];
			textFlowOp.bookID = bookID; 
			textFlowOp.sourceID = sourceID;
			textFlowOp.sourceSpecificID = sourceSpecificID;
			textFlowOp.localFilename = [aBook valueForKey:textFlowOp.filenameKey];
			textFlowOp.storeCoordinator = [moc persistentStoreCoordinator];
			textFlowOp.cacheDirectory = cacheDir;
			textFlowOp.tempDirectory = tempDir;
			[self.preAvailabilityQueue addOperation:textFlowOp];
			[bookOps addObject:textFlowOp];
			
			NSArray *textFlowPreAvailOps = [BlioTextFlow preAvailabilityOperations];
			for (BlioProcessingOperation *preAvailOp in textFlowPreAvailOps) {
				preAvailOp.bookID = bookID;
				preAvailOp.sourceID = sourceID;
				preAvailOp.sourceSpecificID = sourceSpecificID;
				preAvailOp.storeCoordinator = [moc persistentStoreCoordinator];
				preAvailOp.cacheDirectory = cacheDir;
				preAvailOp.tempDirectory = tempDir;
				[preAvailOp addDependency:textFlowOp];
				[self.preAvailabilityQueue addOperation:preAvailOp];
				[bookOps addObject:preAvailOp];
			}
			
			NSArray *flowViewPreAvailOps = [BlioFlowView preAvailabilityOperations];
			for (BlioProcessingOperation *preAvailOp in flowViewPreAvailOps) {
				preAvailOp.bookID = bookID;
				preAvailOp.storeCoordinator = [moc persistentStoreCoordinator];
				preAvailOp.cacheDirectory = cacheDir;
				preAvailOp.tempDirectory = tempDir;
				for(BlioProcessingOperation *beforeOp in textFlowPreAvailOps) {
					[preAvailOp addDependency:beforeOp];
				}
				[self.preAvailabilityQueue addOperation:preAvailOp];
				[bookOps addObject:preAvailOp];
			}                    
			
			[textFlowOp release];
		}
		stringURL = [aBook valueForKey:@"audiobookFilename"];
		if (stringURL != nil && [stringURL rangeOfString:@"://"].location != NSNotFound) url = [NSURL URLWithString:stringURL];
		else url = nil;
		
		if (nil != url) {
			BlioProcessingDownloadAudiobookOperation *audiobookOp = [[BlioProcessingDownloadAudiobookOperation alloc] initWithUrl:url];
			audiobookOp.bookID = bookID;
			audiobookOp.sourceID = sourceID;
			audiobookOp.sourceSpecificID = sourceSpecificID;
			audiobookOp.localFilename = [aBook valueForKey:audiobookOp.filenameKey];
			audiobookOp.storeCoordinator = [moc persistentStoreCoordinator];
			audiobookOp.cacheDirectory = cacheDir;
			audiobookOp.tempDirectory = tempDir;
			[self.preAvailabilityQueue addOperation:audiobookOp];
			[bookOps addObject:audiobookOp];
			[audiobookOp release];
		}
		
		BlioProcessingCompleteOperation *completeOp = [[BlioProcessingCompleteOperation alloc] init];
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
	}
}
- (void)pauseProcessingForBook:(BlioMockBook*)aBook {
    NSManagedObjectContext *moc = self.managedObjectContext;
    if (moc == nil) {
		NSLog(@"WARNING: enqueueing book attempted while Processing Manager MOC == nil!");
		return;
	}
    [aBook setValue:[NSNumber numberWithInt:kBlioMockBookProcessingStatePaused] forKey:@"processingComplete"];
	[[self processingCompleteOperationForSourceID:aBook.sourceID sourceSpecificID:aBook.sourceSpecificID] cancel];
	
	NSArray * relatedOperations = [self processingOperationsForSourceID:aBook.sourceID sourceSpecificID:aBook.sourceSpecificID];
	for (BlioProcessingOperation * op in relatedOperations) {
		[op cancel];
	}
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

@end