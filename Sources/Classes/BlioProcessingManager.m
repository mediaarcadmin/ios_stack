//
//  BlioProcessingManager.m
//  BlioApp
//
//  Created by matt on 24/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioBookManager.h"
#import "BlioProcessingManager.h"
#import "BlioProcessingStandardOperations.h"
#import "BlioFlowView.h"
#import "BlioStoreManager.h"
#import "BlioAlertManager.h"

@interface BlioProcessingManager()
@property (nonatomic, retain) NSOperationQueue *preAvailabilityQueue;
@property (nonatomic, retain) NSOperationQueue *postAvailabilityQueue;

- (void)addTextFlowOpToBookOps:(NSMutableArray *)bookOps forBook:(BlioBook *)aBook manifestLocation:(NSString *)manifestLocation withDependency:(NSOperation *)dependencyOp;
- (void)addCoverOpToBookOps:(NSMutableArray *)bookOps forBook:(BlioBook *)aBook manifestLocation:(NSString *)manifestLocation withDependency:(NSOperation *)dependencyOp;

@end

@implementation BlioProcessingManager

@synthesize preAvailabilityQueue, postAvailabilityQueue;

- (void)dealloc {
    [self.preAvailabilityQueue cancelAllOperations];
    [self.postAvailabilityQueue cancelAllOperations];
    self.preAvailabilityQueue = nil;
    self.postAvailabilityQueue = nil;
    [super dealloc];
}

- (id)init{
    if ((self = [super init])) {
        NSOperationQueue *aPreAvailabilityQueue = [[NSOperationQueue alloc] init];
		[aPreAvailabilityQueue setMaxConcurrentOperationCount:3];
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
- (void)enqueueBookWithTitle:(NSString *)title authors:(NSArray *)authors coverPath:(NSString *)coverPath 
					ePubPath:(NSString *)ePubPath pdfPath:(NSString *)pdfPath xpsPath:(NSString *)xpsPath textFlowPath:(NSString *)textFlowPath 
			   audiobookPath:(NSString *)audiobookPath {
	// for legacy compatibility (pre-sourceID and sourceSpecificID)
	[self enqueueBookWithTitle:title authors:authors coverPath:coverPath 
					  ePubPath:ePubPath pdfPath:pdfPath xpsPath:(NSString *)xpsPath textFlowPath:textFlowPath 
				 audiobookPath:audiobookPath sourceID:BlioBookSourceLocalBundle sourceSpecificID:title placeholderOnly:NO];
}
- (void)enqueueBookWithTitle:(NSString *)title authors:(NSArray *)authors coverPath:(NSString *)coverPath 
					ePubPath:(NSString *)ePubPath pdfPath:(NSString *)pdfPath xpsPath:(NSString *)xpsPath textFlowPath:(NSString *)textFlowPath 
			   audiobookPath:(NSString *)audiobookPath sourceID:(BlioBookSourceID)sourceID sourceSpecificID:(NSString*)sourceSpecificID {
	[self enqueueBookWithTitle:title authors:authors coverPath:coverPath 
					  ePubPath:ePubPath pdfPath:pdfPath xpsPath:xpsPath textFlowPath:textFlowPath 
				 audiobookPath:audiobookPath sourceID:sourceID sourceSpecificID:sourceSpecificID placeholderOnly:NO];    
}
- (void)enqueueBookWithTitle:(NSString *)title authors:(NSArray *)authors coverPath:(NSString *)coverPath 
					ePubPath:(NSString *)ePubPath pdfPath:(NSString *)pdfPath  xpsPath:(NSString *)xpsPath textFlowPath:(NSString *)textFlowPath 
			   audiobookPath:(NSString *)audiobookPath sourceID:(BlioBookSourceID)sourceID sourceSpecificID:(NSString*)sourceSpecificID placeholderOnly:(BOOL)placeholderOnly {    
	[self enqueueBookWithTitle:title authors:authors coverPath:coverPath 
					  ePubPath:ePubPath pdfPath:pdfPath xpsPath:xpsPath textFlowPath:textFlowPath 
				 audiobookPath:audiobookPath sourceID:sourceID sourceSpecificID:sourceSpecificID placeholderOnly:NO fromBundle:NO];    
	
}
- (void)enqueueBookWithTitle:(NSString *)title authors:(NSArray *)authors coverPath:(NSString *)coverPath 
					ePubPath:(NSString *)ePubPath pdfPath:(NSString *)pdfPath  xpsPath:(NSString *)xpsPath textFlowPath:(NSString *)textFlowPath 
			   audiobookPath:(NSString *)audiobookPath sourceID:(BlioBookSourceID)sourceID sourceSpecificID:(NSString*)sourceSpecificID placeholderOnly:(BOOL)placeholderOnly fromBundle:(BOOL)fromBundle {    
	
    NSManagedObjectContext *moc = [[BlioBookManager sharedBookManager] managedObjectContextForCurrentThread];
    if (nil != moc) {
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:[NSEntityDescription entityForName:@"BlioBook" inManagedObjectContext:moc]];        
        
        NSError *error;
        BlioBook *aBook = nil;
        
        NSUInteger count = [moc countForFetchRequest:request error:&error];
        [request release];
        if (count == NSNotFound) {
            NSLog(@"Failed to retrieve book count with error: %@, %@", error, [error userInfo]);
            return;
        } 
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[NSEntityDescription entityForName:@"BlioBook" inManagedObjectContext:moc]];
//			NSLog(@"sourceSpecificID: %@",sourceSpecificID);
//			NSLog(@"sourceID: %i",sourceID);
		[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"sourceSpecificID == %@ && sourceID == %@", sourceSpecificID,[NSNumber numberWithInt:sourceID]]];
		
		NSError *errorExecute = nil; 
		NSArray *results = [moc executeFetchRequest:fetchRequest error:&errorExecute]; 
		[fetchRequest release];
		
		if (errorExecute) {
			NSLog(@"Error getting executeFetchRequest results. %@, %@", errorExecute, [errorExecute userInfo]);
			return;
		}
		if ([results count] > 1) {
			NSLog(@"WARNING: More than one book found with sourceSpecificID:%@ and sourceID:%i",sourceSpecificID,sourceID); 
		} else if ([results count] == 1) {

			NSLog(@"Processing Manager: Found Book in context already"); 
			
			aBook = [results objectAtIndex:0];
			
			
			if ([[aBook valueForKey:@"processingState"] isEqualToNumber: [NSNumber numberWithInt:kBlioBookProcessingStateComplete]]) {
				NSLog(@"WARNING: enqueue method called on already complete book with sourceSpecificID:%@ and sourceID:%i",sourceSpecificID,sourceID);
				NSLog(@"Aborting enqueue by prematurely returning...");
				return;
			}
		} else {
			// create a new book in context from scratch
//			NSLog(@"Processing Manager: Creating new book"); 
            aBook = [NSEntityDescription insertNewObjectForEntityForName:@"BlioBook" inManagedObjectContext:moc];
		}
		
        [aBook setValue:title forKey:@"title"];
        [aBook setValue:[NSNumber numberWithInt:sourceID] forKey:@"sourceID"];
        [aBook setValue:sourceSpecificID forKey:@"sourceSpecificID"];
        [aBook setValue:[authors lastObject] forKey:@"author"];
        [aBook setValue:[NSNumber numberWithInt:count] forKey:@"libraryPosition"];        
        if (placeholderOnly) [aBook setValue:[NSNumber numberWithInt:kBlioBookProcessingStateNotProcessed] forKey:@"processingState"];
        else [aBook setValue:[NSNumber numberWithInt:kBlioBookProcessingStateIncomplete] forKey:@"processingState"];
        
		NSString * locationValue = nil;
		if (fromBundle) locationValue = BlioManifestEntryLocationBundle;
		else locationValue = BlioManifestEntryLocationWeb;
        if (coverPath != nil) {
            NSDictionary *manifestEntry = [NSMutableDictionary dictionary];
            [manifestEntry setValue:locationValue forKey:@"location"];
            [manifestEntry setValue:coverPath forKey:@"path"];
            [aBook setManifestValue:manifestEntry forKey:@"coverFilename"];
        }
		if (ePubPath != nil) {
            NSDictionary *manifestEntry = [NSMutableDictionary dictionary];
            [manifestEntry setValue:locationValue forKey:@"location"];
            [manifestEntry setValue:ePubPath forKey:@"path"];
            [aBook setManifestValue:manifestEntry forKey:@"epubFilename"];
        }
        if (pdfPath != nil) {
            NSDictionary *manifestEntry = [NSMutableDictionary dictionary];
            [manifestEntry setValue:locationValue forKey:@"location"];
            [manifestEntry setValue:pdfPath forKey:@"path"];
            [aBook setManifestValue:manifestEntry forKey:@"pdfFilename"];
        }
        if (xpsPath != nil) {
            NSDictionary *manifestEntry = [NSMutableDictionary dictionary];
            [manifestEntry setValue:locationValue forKey:@"location"];
            [manifestEntry setValue:xpsPath forKey:@"path"];
            [aBook setManifestValue:manifestEntry forKey:@"xpsFilename"];
        }
        if (textFlowPath != nil) {
            NSDictionary *manifestEntry = [NSMutableDictionary dictionary];
            [manifestEntry setValue:locationValue forKey:@"location"];
            [manifestEntry setValue:textFlowPath forKey:@"path"];
            [aBook setManifestValue:manifestEntry forKey:@"textFlowFilename"];
        }
        if (audiobookPath != nil) {
            NSDictionary *manifestEntry = [NSMutableDictionary dictionary];
            [manifestEntry setValue:locationValue forKey:@"location"];
            [manifestEntry setValue:audiobookPath forKey:@"path"];
            [aBook setManifestValue:manifestEntry forKey:@"audiobookFilename"];
        }
		
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
            NSLog(@"[BlioProcessingManager enqueueBookWithTitle:] (saving UUID) Save failed with error: %@, %@", error, [error userInfo]);
        }
		[self enqueueBook:aBook placeholderOnly:placeholderOnly];
	}
}
-(void) enqueueBook:(BlioBook*)aBook {
	[self enqueueBook:aBook placeholderOnly:NO];
}

-(void) enqueueBook:(BlioBook*)aBook placeholderOnly:(BOOL)placeholderOnly {
//	NSLog(@"BlioProcessingManager enqueueBook: %@",aBook);

	// NOTE: we're making the assumption that the processing manager is using the same MOC as the LibraryView!!!
    NSManagedObjectContext *moc = [[BlioBookManager sharedBookManager] managedObjectContextForCurrentThread];
    if (moc == nil) {
		NSLog(@"WARNING: enqueueing book attempted while Processing Manager MOC == nil!");
		return;
	}
	
	// TODO: Create BlioBookSource objects that contain a BOOL that indicates whether or not login is necessary for this book source.
	if ([[aBook valueForKey:@"sourceID"] intValue] == BlioBookSourceOnlineStore) {
		if (0) { // TODO  reinstate the logged in check
        //if (![[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore]) {
// N.B. - we aren't showing a login view here since we now show one at the launch of the app (if valid login credentials are not present).
//			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDismissed:) name:BlioLoginFinished object:[BlioStoreManager sharedInstance]];
//			[[BlioStoreManager sharedInstance] requestLoginForSourceID:BlioBookSourceOnlineStore];
			return;
		}
		else {
			// get XPS URL
//			NSError * error;

			NSURL * xpsURL = [[BlioStoreManager sharedInstance] URLForBookWithSourceID:[[aBook valueForKey:@"sourceSpecificID"] intValue] sourceSpecificID:[aBook valueForKey:@"sourceSpecificID"]];
			if (xpsURL != nil) {
				NSLog(@"[xpsURL absoluteString]: %@",[xpsURL absoluteString]);
//				[aBook setValue:[xpsURL absoluteString] forKey:@"xpsFilename"];
//				if (![moc save:&error]) {
//					NSLog(@"Save failed for xps filename in processing manager with error: %@, %@", error, [error userInfo]);
//				}				
			}

		}		
	}


	NSManagedObjectID *bookID = [aBook objectID];
	NSString *cacheDir = [aBook bookCacheDirectory];
	NSString *tempDir = [aBook bookTempDirectory];
	BlioBookSourceID sourceID = [[aBook sourceID] intValue];
	NSString *sourceSpecificID = [aBook sourceSpecificID];
	
	if ([[aBook valueForKey:@"processingState"] isEqualToNumber: [NSNumber numberWithInt:kBlioBookProcessingStateComplete]]) {
		NSLog(@"WARNING: enqueue method called on already complete book!");
		NSLog(@"Aborting enqueue by prematurely returning...");
		return;
	}
	if (![[aBook valueForKey:@"processingState"] isEqualToNumber: [NSNumber numberWithInt:kBlioBookProcessingStateNotProcessed]] && placeholderOnly) {
		NSLog(@"WARNING: enqueue method with placeholderOnly called on a book that is in a state other than NotProcessed!");
		NSLog(@"Aborting enqueue by prematurely returning...");
		return;			
	}
	if ([[aBook valueForKey:@"processingState"] isEqualToNumber: [NSNumber numberWithInt:kBlioBookProcessingStateIncomplete]]) {
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
	NSString * manifestLocation = nil;
	NSUInteger alreadyCompletedOperations = 0;
//	NSString * bundlePath = [[NSBundle mainBundle] bundlePath];
	
	manifestLocation = [aBook manifestLocationForKey:@"coverFilename"];

	if (manifestLocation) {
		if ([manifestLocation isEqualToString:BlioManifestEntryLocationFileSystem]) {
			url = nil;
			alreadyCompletedOperations++;
		} else if (![manifestLocation isEqualToString:BlioManifestEntryLocationXPS]) {
            // Don't handle the cover for a paid book here - we do it in paid book processing
            [self addCoverOpToBookOps:bookOps forBook:aBook manifestLocation:manifestLocation withDependency:nil];
        }
	}
	
	manifestLocation = [aBook manifestLocationForKey:@"epubFilename"];
	if (manifestLocation) {
		if ([manifestLocation isEqualToString:BlioManifestEntryLocationFileSystem] || placeholderOnly) {
			alreadyCompletedOperations++;
			url = nil;
		}
		else {
			BOOL usedPreExistingOperation = NO;
			BlioProcessingDownloadEPubOperation * ePubOp = nil;
			stringURL = [aBook manifestPathForKey:@"epubFilename"];
			if (stringURL != nil) {
				// we still need to finish downloading this file
				// so check to see if operation already exists
				ePubOp = (BlioProcessingDownloadEPubOperation*)[self operationByClass:NSClassFromString(@"BlioProcessingDownloadEPubOperation") forSourceID:sourceID sourceSpecificID:sourceSpecificID];
				
				if (!ePubOp || ePubOp.isCancelled) // TODO: honor force reprocess option here
				{
					if ([manifestLocation isEqualToString:BlioManifestEntryLocationBundle]) {
						url = [NSURL fileURLWithPath:stringURL];
					}
					else url = [NSURL URLWithString:stringURL];				
					ePubOp = [[[BlioProcessingDownloadEPubOperation alloc] initWithUrl:url] autorelease];
					ePubOp.bookID = bookID;
					ePubOp.sourceID = sourceID;
					ePubOp.sourceSpecificID = sourceSpecificID;
					ePubOp.localFilename = [aBook manifestPathForKey:ePubOp.filenameKey];
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
	}
	
	manifestLocation = [aBook manifestLocationForKey:@"pdfFilename"];
	if (manifestLocation) {
		if ([manifestLocation isEqualToString:BlioManifestEntryLocationFileSystem] || placeholderOnly) {
			alreadyCompletedOperations++;
			url = nil;
		}
		else {
			stringURL = [aBook manifestPathForKey:@"pdfFilename"];
			BOOL usedPreExistingOperation = NO;
			BlioProcessingDownloadPdfOperation * pdfOp = nil;
			
			if (stringURL != nil) {
				// we still need to finish downloading this file
				// so check to see if operation already exists
				pdfOp = (BlioProcessingDownloadPdfOperation*)[self operationByClass:NSClassFromString(@"BlioProcessingDownloadPdfOperation") forSourceID:sourceID sourceSpecificID:sourceSpecificID];
				
				if (!pdfOp || pdfOp.isCancelled) {
					
					if ([manifestLocation isEqualToString:BlioManifestEntryLocationBundle]) {
						url = [NSURL fileURLWithPath:stringURL];
					}
					else url = [NSURL URLWithString:stringURL];				
					pdfOp = [[[BlioProcessingDownloadPdfOperation alloc] initWithUrl:url] autorelease];
					pdfOp.bookID = bookID;
					pdfOp.sourceID = sourceID;
					pdfOp.sourceSpecificID = sourceSpecificID;
					pdfOp.localFilename = [aBook manifestPathForKey:pdfOp.filenameKey];
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
	}

	manifestLocation = [aBook manifestLocationForKey:@"textFlowFilename"];
	if (manifestLocation) {
		if ([[aBook manifestLocationForKey:@"textFlowFilename"] isEqualToString:BlioManifestEntryLocationTextflow] || placeholderOnly) {
			alreadyCompletedOperations++;
			url = nil;
		}
		else {
			[self addTextFlowOpToBookOps:bookOps forBook:aBook manifestLocation:manifestLocation withDependency:nil];                  			
		}
	}
	
	manifestLocation = [aBook manifestLocationForKey:@"audiobookFilename"];
	if (manifestLocation) {
		if ([manifestLocation isEqualToString:BlioManifestEntryLocationFileSystem] || placeholderOnly) {
			alreadyCompletedOperations++;
			url = nil;
		}
		else {
			stringURL = [aBook manifestPathForKey:@"audiobookFilename"];
			BOOL usedPreExistingOperation = NO;
			BlioProcessingDownloadAudiobookOperation * audiobookOp = nil;
			
			if (stringURL != nil) {
				// we still need to finish downloading this file
				// so check to see if operation already exists
				audiobookOp = (BlioProcessingDownloadAudiobookOperation*)[self operationByClass:NSClassFromString(@"BlioProcessingDownloadAudiobookOperation") forSourceID:sourceID sourceSpecificID:sourceSpecificID];
				if (!audiobookOp || audiobookOp.isCancelled) {
					if ([manifestLocation isEqualToString:BlioManifestEntryLocationBundle]) {
						url = [NSURL fileURLWithPath:stringURL];
					}
					else url = [NSURL URLWithString:stringURL];								
					audiobookOp = [[[BlioProcessingDownloadAudiobookOperation alloc] initWithUrl:url] autorelease];
					audiobookOp.bookID = bookID;
					audiobookOp.sourceID = sourceID;
					audiobookOp.sourceSpecificID = sourceSpecificID;
					audiobookOp.localFilename = [aBook manifestPathForKey:audiobookOp.filenameKey];
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
	}
    
    // non-encrypted XPS books
    manifestLocation = [aBook manifestLocationForKey:@"xpsFilename"];
	if (manifestLocation && (sourceID != BlioBookSourceOnlineStore)) {
		if ([manifestLocation isEqualToString:BlioManifestEntryLocationFileSystem] || placeholderOnly) {
			alreadyCompletedOperations++;
			url = nil;
		}
		else {
			stringURL = [aBook manifestPathForKey:@"xpsFilename"];
			BOOL usedPreExistingOperation = NO;
			BlioProcessingDownloadXPSOperation * xpsOp = nil;
			
			if (stringURL != nil) {
				// we still need to finish downloading this file
				// so check to see if operation already exists
				xpsOp = (BlioProcessingDownloadXPSOperation*)[self operationByClass:NSClassFromString(@"BlioProcessingDownloadXPSOperation") forSourceID:sourceID sourceSpecificID:sourceSpecificID];
				if (!xpsOp || xpsOp.isCancelled) {
					if ([manifestLocation isEqualToString:BlioManifestEntryLocationBundle]) {
						url = [NSURL fileURLWithPath:stringURL];
					}
					else url = [NSURL URLWithString:stringURL];				
					xpsOp = [[[BlioProcessingDownloadXPSOperation alloc] initWithUrl:url] autorelease];
					xpsOp.bookID = bookID;
					xpsOp.sourceID = sourceID;
					xpsOp.sourceSpecificID = sourceSpecificID;
					xpsOp.localFilename = [aBook manifestPathForKey:xpsOp.filenameKey];
					xpsOp.cacheDirectory = cacheDir;
					xpsOp.tempDirectory = tempDir;
					[self.preAvailabilityQueue addOperation:xpsOp];
				}
				else {
					// we reuse existing one
					usedPreExistingOperation = YES;
				}
				[bookOps addObject:xpsOp];
			}
		}	
	}
    
    
	// paid books only.
	manifestLocation = [aBook manifestLocationForKey:@"xpsFilename"];
	if (manifestLocation && (sourceID == BlioBookSourceOnlineStore)) {
		if ([manifestLocation isEqualToString:BlioManifestEntryLocationFileSystem] || placeholderOnly) {
			alreadyCompletedOperations++;
			url = nil;
		}
		else {
			stringURL = [aBook manifestPathForKey:@"xpsFilename"];
			BOOL usedPreExistingOperation = NO;
			BlioProcessingDownloadPaidBookOperation * paidBookOp = nil;
			
			if (stringURL != nil) {
				// we still need to finish downloading this file
				// so check to see if operation already exists
				paidBookOp = (BlioProcessingDownloadPaidBookOperation*)[self operationByClass:NSClassFromString(@"BlioProcessingPaidBookDownloadOperation") forSourceID:sourceID sourceSpecificID:sourceSpecificID];
				if (!paidBookOp || paidBookOp.isCancelled) {
					if ([manifestLocation isEqualToString:BlioManifestEntryLocationBundle]) {
						url = [NSURL fileURLWithPath:stringURL];
					}
					else url = [NSURL URLWithString:stringURL];				
					paidBookOp = [[[BlioProcessingDownloadPaidBookOperation alloc] initWithUrl:url] autorelease];
					paidBookOp.bookID = bookID;
					paidBookOp.sourceID = sourceID;
					paidBookOp.sourceSpecificID = sourceSpecificID;
					paidBookOp.localFilename = [aBook manifestPathForKey:paidBookOp.filenameKey];
					paidBookOp.cacheDirectory = cacheDir;
					paidBookOp.tempDirectory = tempDir;
					[self.preAvailabilityQueue addOperation:paidBookOp];
				}
				else {
					// we reuse existing one
					usedPreExistingOperation = YES;
				}
				[bookOps addObject:paidBookOp];
			}
            
            if ([[aBook manifestLocationForKey:@"coverFilename"] isEqualToString:BlioManifestEntryLocationXPS] || placeholderOnly) {
                alreadyCompletedOperations++;
                url = nil;
            } else {
                [self addCoverOpToBookOps:bookOps forBook:aBook manifestLocation:nil withDependency:paidBookOp];
            }
            
            BlioProcessingOperation * licenseOp = [self operationByClass:NSClassFromString(@"BlioProcessingLicenseAcquisitionOperation") forSourceID:sourceID sourceSpecificID:sourceSpecificID];
			if (!licenseOp || licenseOp.isCancelled) {
				licenseOp = [[[BlioProcessingLicenseAcquisitionOperation alloc] init] autorelease];
				licenseOp.bookID = bookID;
				licenseOp.sourceID = sourceID;
				licenseOp.sourceSpecificID = sourceSpecificID;
				licenseOp.cacheDirectory = cacheDir;
				licenseOp.tempDirectory = tempDir;
				if (paidBookOp && usedPreExistingOperation == NO) [licenseOp addDependency:paidBookOp];
				[self.preAvailabilityQueue addOperation:licenseOp];
				[bookOps addObject:licenseOp];
			}
			else {
				// if it already exists, it is dependent on a completed operation
			}

            if ([[aBook manifestLocationForKey:@"textFlowFilename"] isEqualToString:BlioManifestEntryLocationXPS] || placeholderOnly) {
                alreadyCompletedOperations++;
                url = nil;
            } else {
                [self addTextFlowOpToBookOps:bookOps forBook:aBook manifestLocation:nil withDependency:licenseOp];                  			
            }
			
		}	
	}
	
	BlioProcessingCompleteOperation *completeOp = [[BlioProcessingCompleteOperation alloc] init];
	[completeOp setQueuePriority:NSOperationQueuePriorityVeryHigh];
	completeOp.alreadyCompletedOperations = alreadyCompletedOperations;
	completeOp.bookID = bookID;
	completeOp.sourceID = sourceID;
	completeOp.sourceSpecificID = sourceSpecificID;
	completeOp.cacheDirectory = cacheDir;
	completeOp.tempDirectory = tempDir;
	
	
	for (NSOperation *op in bookOps) {
		[completeOp addDependency:op];
	}
	
	[self.preAvailabilityQueue addOperation:completeOp];
	[completeOp calculateProgress];
	[completeOp release];
	
	// now that completeOp is in queue, we change the model (which in turn triggers a refresh in LibraryView; the gridcell can successfully find the completeOp in the queue and become a listener to it.
	if ([[aBook valueForKey:@"processingState"] intValue] != kBlioBookProcessingStateIncomplete && [[aBook valueForKey:@"processingState"] intValue] != kBlioBookProcessingStateNotProcessed) {
		// if book is paused, reflect unpausing in state
		[aBook setValue:[NSNumber numberWithInt:kBlioBookProcessingStateIncomplete] forKey:@"processingState"];			
		NSError * error;
		if (![moc save:&error]) {
			NSLog(@"[BlioProcessingManager enqueueBook:placeholderOnly:] (changing state to incomplete) Save failed with error: %@, %@", error, [error userInfo]);
		}			
	}		
}

- (void)addCoverOpToBookOps:(NSMutableArray *)bookOps forBook:(BlioBook *)aBook manifestLocation:(NSString *)manifestLocation withDependency:(NSOperation *)dependencyOp {
    
    NSString *stringURL = [aBook manifestPathForKey:@"coverFilename"];
    BlioProcessingDownloadCoverOperation * coverOp = nil;
    
    NSURL *url = nil;
    NSManagedObjectID *bookID = [aBook objectID];
	NSString *cacheDir = [aBook bookCacheDirectory];
	NSString *tempDir = [aBook bookTempDirectory];
	BlioBookSourceID sourceID = [[aBook sourceID] intValue];
	NSString *sourceSpecificID = [aBook sourceSpecificID];
    
    if ((stringURL != nil) && (manifestLocation != nil)) {
        if ([manifestLocation isEqualToString:BlioManifestEntryLocationBundle]) {
            url = [NSURL fileURLWithPath:stringURL];
        }
        else url = [NSURL URLWithString:stringURL];
        coverOp = [[BlioProcessingDownloadCoverOperation alloc] initWithUrl:url];
        coverOp.bookID = bookID;
        coverOp.sourceID = sourceID;
        coverOp.sourceSpecificID = sourceSpecificID;
        coverOp.localFilename = [aBook manifestPathForKey:coverOp.filenameKey];
        coverOp.cacheDirectory = cacheDir;
        coverOp.tempDirectory = tempDir;
        [coverOp setQueuePriority:NSOperationQueuePriorityHigh];
        [self.preAvailabilityQueue addOperation:coverOp];
        [bookOps addObject:coverOp];
        [coverOp release];
    }
        
        BlioProcessingGenerateCoverThumbsOperation *thumbsOp = [[BlioProcessingGenerateCoverThumbsOperation alloc] init];
        thumbsOp.bookID = bookID;
        thumbsOp.sourceID = sourceID;
        thumbsOp.sourceSpecificID = sourceSpecificID;
        thumbsOp.cacheDirectory = cacheDir;
        thumbsOp.tempDirectory = tempDir;
        if (coverOp) [thumbsOp addDependency:coverOp];
        if (dependencyOp) [thumbsOp addDependency:dependencyOp];
        [thumbsOp setQueuePriority:NSOperationQueuePriorityVeryHigh];
        [self.preAvailabilityQueue addOperation:thumbsOp];
        [bookOps addObject:thumbsOp];
        
        [thumbsOp release];
    
}

- (void)addTextFlowOpToBookOps:(NSMutableArray *)bookOps forBook:(BlioBook *)aBook manifestLocation:(NSString *)manifestLocation withDependency:(NSOperation *)dependencyOp {
    NSString *stringURL = [aBook manifestPathForKey:@"textFlowFilename"];
    BOOL usedPreExistingOperation = NO;
    BlioProcessingDownloadTextFlowOperation * textFlowOp = nil;
    NSURL *url = nil;
    NSManagedObjectID *bookID = [aBook objectID];
	NSString *cacheDir = [aBook bookCacheDirectory];
	NSString *tempDir = [aBook bookTempDirectory];
	BlioBookSourceID sourceID = [[aBook sourceID] intValue];
	NSString *sourceSpecificID = [aBook sourceSpecificID];
    
    if ((stringURL != nil) && (manifestLocation != nil)) {
        // we still need to finish downloading this file
        // so check to see if operation already exists
        textFlowOp = (BlioProcessingDownloadTextFlowOperation*)[self operationByClass:NSClassFromString(@"BlioProcessingDownloadTextFlowOperation") forSourceID:sourceID sourceSpecificID:sourceSpecificID];
        if (!textFlowOp || textFlowOp.isCancelled) {
            if ([manifestLocation isEqualToString:BlioManifestEntryLocationBundle]) {
                url = [NSURL fileURLWithPath:stringURL];
            }
            else url = [NSURL URLWithString:stringURL];				
            textFlowOp = [[[BlioProcessingDownloadTextFlowOperation alloc] initWithUrl:url] autorelease];
            textFlowOp.bookID = bookID; 
            textFlowOp.sourceID = sourceID;
            textFlowOp.sourceSpecificID = sourceSpecificID;
            textFlowOp.localFilename = [aBook manifestPathForKey:textFlowOp.filenameKey];
            textFlowOp.cacheDirectory = cacheDir;
            textFlowOp.tempDirectory = tempDir;
            if (dependencyOp) [textFlowOp addDependency:dependencyOp];
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
            preAvailOp.cacheDirectory = cacheDir;
            preAvailOp.tempDirectory = tempDir;
            if (textFlowOp) [preAvailOp addDependency:textFlowOp];
            if (dependencyOp) [preAvailOp addDependency:dependencyOp];
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
    
- (void) resumeProcessing {
    NSManagedObjectContext *moc = [[BlioBookManager sharedBookManager] managedObjectContextForCurrentThread];
	
	// resume previous processing operations
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"BlioBook" inManagedObjectContext:moc]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"processingState == %@", [NSNumber numberWithInt:kBlioBookProcessingStateIncomplete]]];
	
	NSError *errorExecute = nil;
    NSArray *results = [moc executeFetchRequest:fetchRequest error:&errorExecute]; 
    
    if (errorExecute) {
        NSLog(@"Error getting incomplete book results. %@, %@", errorExecute, [errorExecute userInfo]); 
    }
    else {
		if ([results count] > 0) {
			NSLog(@"Found non-paused incomplete book results, will resume..."); 
			for (BlioBook * book in results) {
				[self enqueueBook:book];
			}			
		}
		else {
			//			NSLog(@"No incomplete book results to resume."); 
		}
	}
    [fetchRequest release];
	
	// end resume previous processing operations
}
-(void) resumeProcessingForSourceID:(BlioBookSourceID)bookSource {
    NSManagedObjectContext *moc = [[BlioBookManager sharedBookManager] managedObjectContextForCurrentThread];
	
	// resume previous processing operations
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"BlioBook" inManagedObjectContext:moc]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"processingState == %@ && sourceID == %@", [NSNumber numberWithInt:kBlioBookProcessingStateIncomplete],[NSNumber numberWithInt:bookSource]]];
	
	NSError *errorExecute = nil;
    NSArray *results = [moc executeFetchRequest:fetchRequest error:&errorExecute]; 
    
    if (errorExecute) {
        NSLog(@"Error getting incomplete paid book results. %@, %@", errorExecute, [errorExecute userInfo]); 
    }
    else {
		if ([results count] > 0) {
			NSLog(@"Found non-paused incomplete paid book results, will resume..."); 
			for (BlioBook * book in results) {
				[self enqueueBook:book];
			}
			
		}
		else {
			NSLog(@"No incomplete paid book results to resume."); 
		}
	}
    [fetchRequest release];
	
	// end resume previous processing operations
	
}
- (void)loginDismissed:(NSNotification*)note {
	BlioBookSourceID sourceID = [[[note userInfo] valueForKey:@"sourceID"] intValue];
	if ([[BlioStoreManager sharedInstance] isLoggedInForSourceID:sourceID]) {
		[self resumeProcessingForSourceID:sourceID];
	}
	else {
		// ALERT user that we needed a token from login.
		// TODO: test this logic after the download operation for paid books is complete.
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"For Your Information...",@"\"For Your Information...\" Alert message title")
									 message:[NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"LOGIN_REQUIRED_FOR_PAID_BOOKS_PROCESSING",nil,[NSBundle mainBundle],@"%@ books could not continue processing because you need to login first.",@"Alert message informing the end-user that paid book processing cannot continue because the user needs to login."),@"Paid"]
									delegate:self
						   cancelButtonTitle:@"OK"
						   otherButtonTitles:nil];
	}

}
-(BlioBook*)bookWithSourceID:(BlioBookSourceID)sourceID sourceSpecificID:(NSString*)sourceSpecificID {
    NSManagedObjectContext *moc = [[BlioBookManager sharedBookManager] managedObjectContextForCurrentThread];
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"BlioBook" inManagedObjectContext:moc]];
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"sourceID == %@ && sourceSpecificID == %@",[NSNumber numberWithInt:sourceID],sourceSpecificID]];
	
	NSError *errorExecute = nil;
	NSArray *results = [moc executeFetchRequest:fetchRequest error:&errorExecute]; 
	[fetchRequest release];
	if (errorExecute) {
		NSLog(@"Error searching for paid book in MOC. %@, %@", errorExecute, [errorExecute userInfo]);
		return nil;
	}
	if ([results count] == 1) {
		return (BlioBook*)[results objectAtIndex:0];
	}
	else if ([results count] > 1) {
		NSLog(@"WARNING: multiple books found with same sourceID and sourceSpecificID!");
	}
	return nil;
}
- (void)pauseProcessingForBook:(BlioBook*)aBook {
	NSLog(@"BlioProcessingManager pauseProcessingForBook entered");
    NSManagedObjectContext *moc = [[BlioBookManager sharedBookManager] managedObjectContextForCurrentThread];
    if (moc == nil) {
		NSLog(@"WARNING: pause processing attempted while Processing Manager MOC == nil!");
		return;
	}
    [aBook setValue:[NSNumber numberWithInt:kBlioBookProcessingStatePaused] forKey:@"processingState"];
	[self stopProcessingForBook:aBook];
	NSError * error;
	if (![moc save:&error]) {
		NSLog(@"[BlioProcessingManager pauseProcessingForBook:] (set state to paused) Save failed in processing manager with error: %@, %@", error, [error userInfo]);
	}			
}
- (void)stopProcessingForBook:(BlioBook*)aBook {
    NSManagedObjectContext *moc = [[BlioBookManager sharedBookManager] managedObjectContextForCurrentThread];
    if (moc == nil) {
		NSLog(@"WARNING: stop processing for book attempted while Processing Manager MOC == nil!");
		return;
	}
	[[self processingCompleteOperationForSourceID:[aBook.sourceID intValue] sourceSpecificID:aBook.sourceSpecificID] cancel];
	
	NSArray * relatedOperations = [self processingOperationsForSourceID:[aBook.sourceID intValue] sourceSpecificID:aBook.sourceSpecificID];
	for (BlioProcessingOperation * op in relatedOperations) {
		[op cancel];
	}
}
-(void) deleteBook:(BlioBook*)aBook shouldSave:(BOOL)shouldSave {
	// if book is processing, stop all associated operations
	if ([[aBook valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateIncomplete) [self stopProcessingForBook:aBook];
	
    NSManagedObjectContext *moc = [[BlioBookManager sharedBookManager] managedObjectContextForCurrentThread];
	NSError * error;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	// delete temporary files (which are only present if processing is not complete)
	if ([fileManager fileExistsAtPath:[aBook bookTempDirectory]]) {
		if (![fileManager removeItemAtPath:[aBook bookTempDirectory] error:&error]) {
			NSLog(@"WARNING: deletion of temporary directory for book failed. %@, %@", error, [error userInfo]);
		}
	}
	
	if ([[aBook valueForKey:@"sourceID"] intValue] == BlioBookSourceOnlineStore) {
		// delete all files except the thumbnail so that we can put the book back in the vault.
		NSString * listThumbnailFilename = [aBook valueForKey:@"listThumbFilename"];
		NSString * gridThumbnailFilename = [aBook valueForKey:@"gridThumbFilename"];
		NSString * coverFilename = [aBook valueForKey:@"coverFilename"];
		if ([fileManager fileExistsAtPath:[aBook bookCacheDirectory]]) {
			NSError * directoryContentError;
			NSArray *fileList = [fileManager contentsOfDirectoryAtPath:[aBook bookCacheDirectory] error:&directoryContentError];
			if (fileList != nil) {
				for (NSString * fileName in fileList) {
					NSLog(@"fileName: %@",fileName);
					if (![fileName isEqualToString:listThumbnailFilename] && ![fileName isEqualToString:gridThumbnailFilename] && ![fileName isEqualToString:coverFilename]) {
						if (![fileManager removeItemAtPath:[[aBook bookCacheDirectory] stringByAppendingPathComponent:fileName] error:&error]) {
							NSLog(@"WARNING: deletion of asset for paid book failed. %@, %@", error, [error userInfo]);
						}
					}
				}
				// reset asset values in BlioBook.
				[aBook setManifestValue:nil forKey:@"audiobookFilename"];
				[aBook setManifestValue:nil forKey:@"epubFilename"];
				[aBook setManifestValue:nil forKey:@"pdfFilename"];
				[aBook setManifestValue:nil forKey:@"textFlowFilename"];
				[aBook setManifestValue:nil forKey:@"xpsFilename"];
				[aBook setValue:[NSNumber numberWithInt:kBlioBookProcessingStatePlaceholderOnly] forKey:@"processingState"];
			}
			else {
				NSLog(@"ERROR: could not get directory content listing for paid book. %@, %@", directoryContentError, [directoryContentError userInfo]);
			}
		}
		
		
	}
	else {
		// delete permanent files
		if (![fileManager removeItemAtPath:[aBook bookCacheDirectory] error:&error]) {
			NSLog(@"WARNING: deletion of cache directory for book failed. %@, %@", error, [error userInfo]);
		}
		
		NSInteger deletedBookPosition = [aBook.libraryPosition intValue];
		
		// reposition remaining books with a position value greater than the deleted book
		
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[NSEntityDescription entityForName:@"BlioBook" inManagedObjectContext:moc]];
		
		[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"libraryPosition > %@", [NSNumber numberWithInt:deletedBookPosition]]];
		
		NSError *errorExecute = nil; 
		NSArray *results = [moc executeFetchRequest:fetchRequest error:&errorExecute]; 
		[fetchRequest release];
		
		if (errorExecute) {
			NSLog(@"Error getting executeFetchRequest results. %@, %@", errorExecute, [errorExecute userInfo]);
			return;
		}
		
		for (BlioBook* book in results) {
			NSInteger newPosition = [book.libraryPosition intValue];
			newPosition--;
			[book setValue:[NSNumber numberWithInt:newPosition] forKey:@"libraryPosition"];
		}
		// TODO: make sure all the relationships in the object graph have the appropriate delete rules set.
		
		// delete record. N.B.: this needs to happen after the re-ordering, as the update changeObject events for the re-ordering to the fetchedController delegate should happen after the delete event.
		[moc deleteObject:aBook];
	}
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
- (BlioProcessingCompleteOperation *)processingCompleteOperationForSourceID:(BlioBookSourceID)sourceID sourceSpecificID:(NSString*)sourceSpecificID {
	NSArray * operations = [preAvailabilityQueue operations];
	for (BlioProcessingOperation * op in operations) {
		if ([op isKindOfClass:[BlioProcessingCompleteOperation class]] && (sourceID == op.sourceID) && [sourceSpecificID isEqualToString:op.sourceSpecificID]) {
			return (BlioProcessingCompleteOperation*)op;
		}
	}
	return nil;
}
- (NSArray *)processingOperationsForSourceID:(BlioBookSourceID)sourceID sourceSpecificID:(NSString*)sourceSpecificID {
	NSArray * operations = [preAvailabilityQueue operations];
	NSMutableArray * tempArray = [NSMutableArray array];
	for (BlioProcessingOperation * op in operations) {
		if (sourceID == op.sourceID && [sourceSpecificID isEqualToString:op.sourceSpecificID]) {
			[tempArray addObject:op];
		}
	}
	return tempArray;
}
- (BlioProcessingOperation*) operationByClass:(Class)targetClass forSourceID:(BlioBookSourceID)sourceID sourceSpecificID:(NSString*)sourceSpecificID {
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