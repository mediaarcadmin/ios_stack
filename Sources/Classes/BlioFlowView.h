//
//  BlioFlowView.h
//  BlioApp
//
//  Created by James Montgomerie on 04/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <libEucalyptus/EucBookView.h>
#import <libEucalyptus/EucSelector.h>
#import "BlioBookViewController.h"
#import "BlioProcessingManager.h"
#import "BlioSelectableBookView.h"
#import "BlioTextFlow.h"

@protocol BlioEPubBookmarkPointTranslation;
@class EucEPubBook;

@interface BlioFlowView : BlioSelectableBookView <BlioBookView, EucSelectorDelegate, EucBookViewDelegate, BlioProcessingManagerOperationProvider> {
    NSManagedObjectID *_bookID;
    
    NSString *_fontName;
    NSArray *_fontSizes;
    
    EucBookView *_eucBookView;
    EucEPubBook<BlioEPubBookmarkPointTranslation> *_eucBook;
    id<BlioParagraphSource> _paragraphSource;
    BOOL _pageViewIsTurning;
    BOOL _suppressHistory;
	
	BlioBookmarkPoint *_lastSavedPoint;
	    
    BlioBookmarkPoint *_currentBookmarkPoint;
    
    BlioTextFlowFlowTreeKind _textFlowFlowTreeKind;
}

@property (nonatomic, assign) id<BlioBookViewDelegate> delegate;
@property (nonatomic, retain) NSManagedObjectID *bookID;

@end
