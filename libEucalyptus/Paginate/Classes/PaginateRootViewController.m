//
//  PaginateRootViewController.m
//  Paginate
//
//  Created by James Montgomerie on 05/08/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import "PaginateRootViewController.h"
#import <libEucalyptus/EucBUpeBook.h>
#import <libEucalyptus/EucBUpeZipDataProvider.h>
#import <libEucalyptus/EucBookPageIndex.h>
#import <libEucalyptus/EucBookPaginator.h>
#import <unistd.h>
#import <sys/fcntl.h>
#import <glob.h>

#define PAGINATION_PATH @"/tmp/PaginationResults"
//#define PAGINATION_PATH @"/Volumes/Gutenberg/PaginationResults"

@implementation PaginateRootViewController

@synthesize paginationUnderway;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

/*
 // Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
 */

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release anything that can be recreated in viewDidLoad or on demand.
	// e.g. self.myOutlet = nil;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    if(self.paginationUnderway) {
        cell.textLabel.text = @"Paginating...";
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        cell.accessoryView = activityIndicator;
        [activityIndicator startAnimating];
        [activityIndicator release];
    } else {
        if(indexPath.row == 0) {
            cell.textLabel.text = @"Go!";
        }   else {
            cell.textLabel.text = @"Go with images!";
        }
        cell.accessoryView = nil;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

- (void)removeFilesMatchingPattern:(NSString *)pattern fromPath:(NSString *)path
{
    NSString *globPath = [path stringByAppendingPathComponent:pattern];
    glob_t globValue = { 0 };
    int err = glob([globPath fileSystemRepresentation],
                   GLOB_NOSORT,
                   NULL,
                   &globValue);
    if(err == 0) {
        for(size_t i = 0; i < globValue.gl_pathc; ++i) {
            char *from = globValue.gl_pathv[i];
            NSLog(@"Removing \"%s\"", from);
            unlink(from);
        }
    } else if(err != GLOB_NOMATCH) {
        NSLog(@"Globbing failed when attempting to remove \"%@\", error %ld", globPath, (long)err);
    }
    globfree(&globValue);
}

- (BOOL)paginateNextBook
{
    if(toPaginate.count) {
        NSString *ePubPath = [toPaginate objectAtIndex:0];
        
        
#if TARGET_IPHONE_SIMULATOR
        NSString *temporaryPath = PAGINATION_PATH;
#else
        NSString *temporaryPath = NSTemporaryDirectory();
#endif
        NSString *lastPathComponent = [ePubPath lastPathComponent];
        NSString *paginationDirectory = [temporaryPath stringByAppendingPathComponent:[lastPathComponent stringByDeletingPathExtension]];
        NSString *images = [paginationDirectory stringByAppendingPathComponent:@"/Images"];
        
        [[NSFileManager defaultManager] createDirectoryAtPath:paginationDirectory withIntermediateDirectories:YES attributes:NULL error:NULL];
        
        NSLog(@"Paginating \"%@\"", ePubPath);
        
        // Remove old indexes.
        [self removeFilesMatchingPattern:@"*v*Index*" fromPath:paginationDirectory];
        
        thisBookTime = CFAbsoluteTimeGetCurrent();
        
        EucBUpeZipDataProvider *dataProvider = [[EucBUpeZipDataProvider alloc] initWithZipFileAtPath:ePubPath];
        EucBUpeBook *testBook = [[EucBUpeBook alloc] initWithDataProvider:dataProvider cacheDirectoryPath:paginationDirectory];
        [dataProvider release];
        [paginator paginateBookInBackground:testBook saveImagesTo:saveImages ? images : nil];
        [testBook release];
        return YES;
    }
    return NO;
}

- (void)paginationComplete:(NSNotification *)notification
{
    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
    
    NSString *path = [toPaginate objectAtIndex:0];
    NSLog(@"Pagination complete for %@, %f seconds.", path, currentTime - thisBookTime);
    
    [toPaginate removeObjectAtIndex:0];
                                  
    if(![self paginateNextBook]) {
        NSLog(@"Pagination done in %f seconds.", currentTime - time);
        [toPaginate release];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:EucBookPaginatorCompleteNotification object:paginator];
        [paginator release];
        self.paginationUnderway = NO;
        [self.tableView reloadData];
    }
}


// Override to support row selection in the table view.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(!self.paginationUnderway) {
        saveImages = (indexPath.row == 1);
        
        toPaginate = [[NSMutableArray alloc] init];
        NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
        for(NSString *resource in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:resourcePath error:nil]) {
            NSString *fullPath = [resourcePath stringByAppendingPathComponent:resource];
            if([[fullPath pathExtension] caseInsensitiveCompare:@"epub"] == NSOrderedSame) {
                [toPaginate addObject:fullPath];
            }
        }        
    
        paginator = [[EucBookPaginator alloc] init];        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(paginationComplete:)
                                                     name:EucBookPaginatorCompleteNotification
                                                   object:paginator];
        
        [[NSFileManager defaultManager] removeItemAtPath:PAGINATION_PATH error:nil];
        [[NSFileManager defaultManager] createDirectoryAtPath:PAGINATION_PATH withIntermediateDirectories:YES attributes:nil error:nil];
        
        time = CFAbsoluteTimeGetCurrent();
        if([self paginateNextBook]) {
            self.paginationUnderway = YES;
        } else {
            [toPaginate release];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:EucBookPaginatorCompleteNotification object:paginator];
            [paginator release];
            self.paginationUnderway = NO;            
        }
        [self.tableView reloadData];
    } else {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}



/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


- (void)dealloc {
    [super dealloc];
}


@end

