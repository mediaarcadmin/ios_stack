/*
 *  BlioBookView.h
 *  BlioApp
 *
 *  Created by James Montgomerie on 05/01/2010.
 *  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
 *
 */

@protocol BlioBookView <NSObject>

@required
- (void)jumpToUuid:(NSString *)uuid;
- (void)setPageNumber:(NSInteger)pageNumber animated:(BOOL)animated;

@property (nonatomic, assign) NSInteger pageNumber;
@property (nonatomic, readonly) id<EucBookContentsTableViewControllerDataSource> contentsDataSource;

@optional
@property (nonatomic, assign) CGFloat fontPointSize;

@end