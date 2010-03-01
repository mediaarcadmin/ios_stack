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
    encyclopediaTool = 1,
    searchTool = 2,
} BlioWebToolsType;

typedef enum  {
    googleOption = 0,
    yahooOption = 1,
    bingOption = 2,
} BlioSearchEngineOption;

typedef enum  {
    wikipediaOption = 0,
    britannicaOption = 1,
} BlioEncyclopediaOption;

@interface BlioWebToolsViewController : UINavigationController<UIWebViewDelegate> {
    BOOL statusBarHiddenOnEntry;
	NSArray* urls;
}

- (id)initWithURL:(NSURL *)url;

@end
