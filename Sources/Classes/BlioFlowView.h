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

@class EucBUpeBook;

@interface BlioFlowView : BlioSelectableBookView <BlioBookView, EucSelectorDelegate, EucBookViewDelegate, BlioProcessingManagerOperationProvider> {
    NSManagedObjectID *_bookID;
    
    EucBookView *_eucBookView;
    EucBUpeBook *_eucBook;
    id<BlioParagraphSource> _paragraphSource;
    BOOL _pageViewIsTurning;
    
    id<BlioBookViewDelegate> _delegate;
    
    NSInteger _pageCount;
    NSInteger _pageNumber;
    
    BlioTextFlowFlowTreeKind _textFlowFlowTreeKind;
}

@property (nonatomic, assign) id<BlioBookViewDelegate> delegate;
@property (nonatomic, retain) NSManagedObjectID *bookID;

@end
