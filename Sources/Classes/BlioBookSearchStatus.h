/*
 *  BlioBookSearchStatus.h
 *  BlioApp
 *
 *  Created by matt on 11/09/2010.
 *  Copyright 2010 BitWink. All rights reserved.
 *
 */

typedef enum {
    kBlioBookSearchStatusIdle = 0,
    kBlioBookSearchStatusInProgress = 1,
    kBlioBookSearchStatusInProgressHasWrapped = 2,
    kBlioBookSearchStatusComplete = 3,
    kBlioBookSearchStatusStopped = 4
} BlioBookSearchStatus;