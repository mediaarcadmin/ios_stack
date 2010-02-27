//
//  BlioWebToolsViewController.h
//  BlioApp
//
//  Created by matt on 23/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>

#define ACTIVITY_INDICATOR 99

typedef enum  {
    dictionaryTool = 0,
    //thesaurusTool = 1,
    wikipediaTool = 1,
    searchTool = 2,
} BlioWebToolsType;

@interface BlioWebToolsViewController : UINavigationController<UIWebViewDelegate> {
    BOOL statusBarHiddenOnEntry;
}

- (id)initWithURL:(NSURL *)url;

@end
