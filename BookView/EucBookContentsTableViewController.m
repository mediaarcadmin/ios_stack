//
//  BookContentsTableViewController.m
//  Eucalyptus
//
//  Created by James Montgomerie on 20/01/2009.
//  Copyright 2009 James Montgomerie. All rights reserved.
//

#import "EucBookContentsTableViewController.h"
#import "EucBookContentsTableViewCellBackground.h"
#import "EucNameAndPageNumberView.h"
#import "EucPageLayoutController.h"
#import "EucBook.h"
#import "EucBookSection.h"
//#import "BookPaginator.h"
#import "VCTitleCase.h"
#import "THPair.h"
#import "THNSStringAdditions.h"
#import "THRegex.h"
#import "THLog.h"
#import "EucChapterNameFormatting.h"

#define TABLE_CONTENTS_CELL_WIDTH 282
#define TABLE_CONTENTS_CELL_WIDTH_WITH_ACCESSORY 249

@implementation EucBookContentsTableViewController

@synthesize delegate = _delegate;
@synthesize currentSectionUuid = _currentSectionUuid;
@synthesize selectedUuid = _selectedUuid;
/*
- (void)_bookPaginationProgress:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    EucBookReference<EucBook> *book = [userInfo objectForKey:BookPaginationBookKey];
    if(book.etextNumber == _book.etextNumber) {
        UITableView *tableView = self.tableView;
        
        NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
        
        if([notification.name isEqualToString:BookPaginationCompleteNotification]) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:0 inSection:2]];
            _paginationIsComplete = YES;

            NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
            [defaultCenter removeObserver:self name:BookPaginationProgressNotification object:nil];
            [defaultCenter removeObserver:self name:BookPaginationCompleteNotification object:nil];            
        }
        
        off_t newStartOffset = _index.lastOffset;
        // Don't use [[userInfo objectForKey:BookPaginationBytesPaginatedKey] integerValue];
        // Because the index might not have heard the notification we're responding to yet,
        // and we don't want to get ahead of it.

        for(BookSection *section in _book.sections) {
            off_t sectionStart = section.startOffset;
            NSString *sectionUuid = section.uuid;
            if(sectionStart > _previousLastOffset && sectionStart <= newStartOffset) {
                NSArray *tableSectionContents = [_namesAndUuids objectAtIndex:1];
                for(int i = 0; i < tableSectionContents.count; ++i) {
                    NSString *uuid = ((THPair *)[tableSectionContents objectAtIndex:i]).second;
                    if([uuid isEqualToString:sectionUuid]) {
                        [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:1]];
                    }
                }
            }
        }
        
        if(indexPaths.count) {
            [tableView beginUpdates];              
            [tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
            [tableView endUpdates];  
        }        
        
        [indexPaths release];
                
        _previousLastOffset = newStartOffset;
    }
}
*/
- (id)initWithBook:(EucBookReference<EucBook> *)book pageLayoutController:(id<EucPageLayoutController>)pageLayoutController;
{
    if((self = [super initWithStyle:UITableViewStyleGrouped])) {
        _book = [book retain];
        
        _paginationIsComplete = YES;
        _pageLayoutController = [pageLayoutController retain];
        
        /*_previousLastOffset = _index.lastOffset;
        if(index.isFinal) {
            _paginationIsComplete = YES;
        } else {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(_bookPaginationProgress:)
                                                         name:BookPaginationProgressNotification
                                                       object:nil];            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(_bookPaginationProgress:)
                                                         name:BookPaginationCompleteNotification
                                                       object:nil];
        }*/
    }
    return self;
}


- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [_pageLayoutController release];
    [_book release];
    [_namesAndUuids release];
    [_currentSectionUuid release];
    [_selectedGradientColor release];
    [_selectedUuid release];
    //[_titleFormattingRegex release];
    [super dealloc];
}



- (void)viewDidLoad
 {
    [super viewDidLoad];
}

- (NSArray *)_namesAndUuids
{
    if(!_namesAndUuids) {
       /* NSArray *section1 = [[NSArray alloc] initWithObjects:[THPair pairWithFirst:NSLocalizedString(@"Front Cover", @"Title for front cover in chapter list.")
                                                                            second:@"cover"],
                             [THPair pairWithFirst:NSLocalizedString(@"Book Information", @"Title for pre-book information in chapter list.")
                                            second:@"copyright"],
                             nil];
        */
        NSMutableArray *section2 = [[NSMutableArray alloc] init];
        for(EucBookSection *section in [_book sections]) {
            NSString *title = [[section.properties objectForKey:kBookSectionPropertyTitle] lowercaseString];
            if(title) {
                [section2 addPairWithFirst:title second:section.uuid];
            } else if(section2.count == 0) {
                [section2 addPairWithFirst:NSLocalizedString(@"Book Begins", @"Title for book text start in chapter list.")
                                                      second:section.uuid];
            }
        }
        
   /*     NSArray *section3 = [[NSArray alloc] initWithObjects:[THPair pairWithFirst:NSLocalizedString(@"Legal Information", @"Title for front Gutenberg licence in chapter list.")
                                                                            second:@"licence"],
                             nil];
   */     
        _namesAndUuids = [[NSArray alloc] initWithObjects:/*section1, */section2,/* section3,*/ nil];
        //[section1 release];
        [section2 release];
     //   [section3 release];
    }
    return _namesAndUuids;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
    
    NSArray *namesAndUuids = self._namesAndUuids;
    for(NSArray *array in namesAndUuids) {
        for(THPair *nameAndUuid in array) {
            if([nameAndUuid.second isEqualToString:_currentSectionUuid]) {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[array indexOfObject:nameAndUuid]
                                                                          inSection:[namesAndUuids indexOfObject:array]]
                                      atScrollPosition:UITableViewScrollPositionMiddle
                                              animated:NO];
                break;
            }
        }
    }
}


- (void)viewDidAppear:(BOOL)animated
{    
    [super viewDidAppear:animated];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self._namesAndUuids.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ((NSArray *)[self._namesAndUuids objectAtIndex:section]).count;
}

- (THPair *)_splitNameForNameAndUuid:(THPair *)nameAndUuid returningPageNumber:(NSUInteger *)pageNumber pageNumberIsValid:(BOOL *)pageNumberIsValid;
{
    NSString *name = nameAndUuid.first;
    NSString *uuid = nameAndUuid.second;
    
    EucBookSection *section = [_book sectionWithUuid:uuid];
    
    if(pageNumber) {
        if(section) {
            *pageNumber = [_pageLayoutController pageNumberForUuid:uuid];
            //if(!_index.isFinal && section.startOffset > _index.lastOffset) {
            //    *pageNumberIsValid = NO;
            //} else {
                *pageNumberIsValid = YES;
            //}
        } else if([uuid isEqualToString:@"licence"]) {
       //     *pageNumber = _index.lastPageNumber + 1;
       //     *pageNumberIsValid = _paginationIsComplete;
        } else {
            *pageNumber = 0;  
            *pageNumberIsValid = YES;
        }
    }
        
    return [name splitAndFormattedChapterName];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
        EucBookContentsTableViewCellBackground *backgroundView = [[EucBookContentsTableViewCellBackground alloc] initWithFrame:CGRectZero];
        backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        cell.backgroundView = backgroundView;
        
        CGRect contentViewRect = cell.contentView.bounds;
        contentViewRect = CGRectInset(contentViewRect, 9, 9);
        UIView *contentView = [[EucNameAndPageNumberView alloc] initWithFrame:contentViewRect];
        contentView.tag = 49;
        contentView.backgroundColor = [UIColor redColor];
        contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [cell.contentView addSubview:contentView];
        [contentView release];
    }
        
    NSArray *rows = [self._namesAndUuids objectAtIndex:indexPath.section];
            
    EucBookContentsTableViewCellPosition backgroundViewPosition;
    
    NSUInteger rowCount = rows.count;
    NSUInteger rowIndex = indexPath.row;
    if(rowCount == 1) {
        backgroundViewPosition = EucBookContentsTableViewCellPositionSingle;
    } else if(rowIndex == 0) {
        backgroundViewPosition = EucBookContentsTableViewCellPositionTop;
    } else if(rowIndex == rowCount - 1) {
        backgroundViewPosition = EucBookContentsTableViewCellPositionBottom;
    } else {
        backgroundViewPosition = EucBookContentsTableViewCellPositionMiddle;
    }
    
    ((EucBookContentsTableViewCellBackground *)cell.backgroundView).position = backgroundViewPosition;
    
    THPair *nameAndUuid = [rows objectAtIndex:rowIndex];
    
    EucNameAndPageNumberView *nameAndPageNumberView = (EucNameAndPageNumberView *)[cell.contentView viewWithTag:49];
    
    
    NSUInteger pageNumber = 0;
    BOOL pageNumberIsValid = NO;
    THPair *nameAndSubtitle = [self _splitNameForNameAndUuid:nameAndUuid returningPageNumber:&pageNumber pageNumberIsValid:&pageNumberIsValid];
    
    nameAndPageNumberView.name = nameAndSubtitle.first;
    nameAndPageNumberView.subTitle = nameAndSubtitle.second;
    if(pageNumberIsValid) {
        nameAndPageNumberView.pageNumber = [_pageLayoutController displayPageNumberForPageNumber:pageNumber];
        nameAndPageNumberView.textColor = [UIColor blackColor]; 
    } else {
        nameAndPageNumberView.pageNumber = nil;
        nameAndPageNumberView.textColor = [UIColor grayColor]; 
    }
    
    UIColor *backgroundColor;
    if([_currentSectionUuid isEqualToString:nameAndUuid.second]) {
        if(!_selectedGradientColor) {
            CGFloat locationRefs[] = { 0.0f, 1.0f };
            /*CGFloat colorRefs[] = { 234.0f / 255.0f, 232.0f / 255.0f, 236.0 / 255.0f, 1.0f,
                                    212.0f / 255.0f, 206.0f / 255.0f, 195.0 / 255.0f, 1.0f };*/
            /*CGFloat colorRefs[] = { 231.0f / 255.0f, 236.0f / 255.0f, 252.0 / 255.0f, 1.0f,
                                      215.0f / 255.0f, 219.0f / 255.0f, 235.0 / 255.0f, 1.0f };*/
            CGFloat colorRefs[] = { 223.0f / 255.0f, 230.0f / 255.0f, 236.0 / 255.0f, 1.0f,
                                    187.0f / 255.0f, 194 / 255.0f, 200.0 / 255.0f, 1.0f };
            CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
            CGGradientRef gradient = CGGradientCreateWithColorComponents(rgbColorSpace, colorRefs, locationRefs, 2);   
            CGColorSpaceRelease(rgbColorSpace);
            CGFloat height = [EucNameAndPageNumberView heightForWidth:TABLE_CONTENTS_CELL_WIDTH // Sems like very bad form to be hard-coding this... 
                                                          withName:nameAndSubtitle.first 
                                                          subTitle:nameAndSubtitle.second 
                                                        pageNumber:nameAndPageNumberView.pageNumber] + 18;
            UIGraphicsBeginImageContext(CGSizeMake(1, height));
            CGContextDrawLinearGradient(UIGraphicsGetCurrentContext(), gradient, CGPointMake(0.0f, 0.0f), CGPointMake(0.0f, height), 0);
            CGGradientRelease(gradient);
            UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            _selectedGradientColor = [[UIColor alloc] initWithPatternImage:gradientImage];
        }
        backgroundColor = _selectedGradientColor;
    } else {
        backgroundColor = [UIColor whiteColor];   
    }

    ((EucBookContentsTableViewCellBackground *)cell.backgroundView).fillColor = backgroundColor;
    nameAndPageNumberView.backgroundColor = backgroundColor;

    if(!pageNumberIsValid) {
        cell.accessoryView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    } else {
        cell.accessoryView = nil;
    }
    
    [cell.accessoryView release];
    [(UIActivityIndicatorView *)cell.accessoryView startAnimating];
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    THPair *nameAndUuid = [[self._namesAndUuids objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    NSUInteger pageNumber = 0;
    BOOL pageNumberIsValid = NO;
    THPair *nameAndSubtitle = [self _splitNameForNameAndUuid:nameAndUuid returningPageNumber:&pageNumber pageNumberIsValid:&pageNumberIsValid];
    
    CGFloat ret = [EucNameAndPageNumberView heightForWidth:pageNumberIsValid ? TABLE_CONTENTS_CELL_WIDTH : TABLE_CONTENTS_CELL_WIDTH_WITH_ACCESSORY // Seems like very bad form to be hard-coding this... 
                                                  withName:nameAndSubtitle.first 
                                                  subTitle:nameAndSubtitle.second 
                                                pageNumber:pageNumberIsValid ? [_pageLayoutController displayPageNumberForPageNumber:pageNumber] : nil] + 18;
    
    return ret;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if([tableView cellForRowAtIndexPath:indexPath].accessoryView != nil) {
        return nil;
    } else {
        return indexPath;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedUuid = [((THPair *)[((NSArray *)[self._namesAndUuids objectAtIndex:indexPath.section]) objectAtIndex:indexPath.row]).second retain];
    [_delegate bookContentsTableViewController:self didSelectSectionWithUuid:_selectedUuid];
}


@end

