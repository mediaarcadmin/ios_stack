//
//  BlioImportManager.h
//  BlioApp
//
//  Created by Don Shin on 10/9/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioProcessing.h"
#import "pthread.h"

static NSString * const BlioFileSharingScanFinished = @"BlioFileSharingScanFinished";
static NSString * const BlioFileSharingScanStarted = @"BlioFileSharingScanStarted";
static NSString * const BlioFileSharingScanUpdate = @"BlioFileSharingScanUpdate";
static NSString * const BlioFileSharingImportAborted = @"BlioFileSharingImportAborted";

@interface BlioImportableBook : NSObject {
	NSString * fileName;
	NSString * filePath;
	NSString * title;
	NSArray * authors;
	BlioBookSourceID sourceID;
	NSString * sourceSpecificID;
	BOOL isDRM;
	NSOperationQueue *importQueue;
}
@property(nonatomic,retain) NSString * fileName;
@property(nonatomic,retain) NSString * filePath;
@property(nonatomic,retain) NSString * title;
@property(nonatomic,retain) NSArray * authors;
@property(nonatomic,assign) BlioBookSourceID sourceID;
@property(nonatomic,retain) NSString * sourceSpecificID;
@property(nonatomic,assign) BOOL isDRM;
@end
	
@interface BlioImportManager : NSObject {
	NSMutableArray * _importableBooks;
	id<BlioProcessingDelegate> _processingDelegate;
	BOOL isScanningFileSharingDirectory;
	NSThread * scanningThread;
	pthread_mutex_t scanningMutex;
    pthread_mutex_t importableBooksMutex;
}
@property(nonatomic,retain) NSMutableArray * importableBooks;
@property (nonatomic, assign) id<BlioProcessingDelegate> processingDelegate;
@property (nonatomic, assign) BOOL isScanningFileSharingDirectory;

+(BlioImportManager*)sharedImportManager;
+(NSString*)fileSharingDirectory;
+(NSString*)inboxDirectory;
-(void)scanFileSharingDirectory;
-(void)importBookFromFilePath:(NSString*)aFilePath;
-(void)importBook:(BlioImportableBook*)importableBook;

@end
