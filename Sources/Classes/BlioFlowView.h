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

@interface BlioFlowView : EucBookView <BlioBookView, EucSelectorDelegate, EucBookViewDelegate, BlioProcessingManagerOperationProvider> {
    id<BlioParagraphSource> _paragraphSource;
    BOOL _pageViewIsTurning;
    
    id<BlioBookViewDelegate> _bookViewDelegate;
}

@property (nonatomic, assign) id<BlioBookViewDelegate> bookViewDelegate;

@end
