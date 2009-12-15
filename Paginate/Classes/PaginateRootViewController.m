//
//  PaginateRootViewController.m
//  HHGG
//
//  Created by James Montgomerie on 05/08/2009.
//  Copyright James Montgomerie 2009. All rights reserved.
//

#import "PaginateRootViewController.h"
#import <libEucalyptus/EucEPubBook.h>
#import <libEucalyptus/EucBookPageIndex.h>
#import <libEucalyptus/EucBookTextStyle.h>
#import <libEucalyptus/EucBookPaginator.h>
#import <sys/stat.h>
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
    glob_t globValue;
    int err = glob([globPath fileSystemRepresentation],
                   GLOB_NOSORT,
                   NULL,
                   &globValue);
    if(err != 0) {
        NSLog(@"Globbing failed when attempting to remove \"%@\"", globPath);
    } else {
        for(size_t i = 0; i < globValue.gl_pathc; ++i) {
            char *from = globValue.gl_pathv[i];
            NSLog(@"Removing \"%s\"", from);
            unlink(from);
        }
        globfree(&globValue);
    }    
}

- (BOOL)paginateNextBook
{
    if(toPaginate.count) {
        NSString *path = [toPaginate objectAtIndex:0];
        
        NSString *lastPathComponent = [path lastPathComponent];
        NSString *moveTo = [PAGINATION_PATH stringByAppendingPathComponent:lastPathComponent];
        NSString *images = [[PAGINATION_PATH stringByAppendingPathComponent:@"/Images"] stringByAppendingPathComponent:lastPathComponent];
        [[NSFileManager defaultManager] copyItemAtPath:path toPath:moveTo error:nil];
        
        path = moveTo;
        [toPaginate replaceObjectAtIndex:0 withObject:path];
        NSLog(@"Paginating \"%@\"", path);
        
        // Remove old indexes.
        [self removeFilesMatchingPattern:@"*.v*index*" fromPath:path];
        [self removeFilesMatchingPattern:@"chapterOffsets.plist" fromPath:path];
        
        EucEPubBook *testBook = [[EucEPubBook alloc] initWithPath:moveTo];    
        [paginator paginateBookInBackground:testBook forForFontFamily:[EucBookTextStyle defaultFontFamilyName] saveImagesTo:saveImages ? images : nil];
        [testBook release];
        return YES;
    }
    return NO;
}

- (void)paginationComplete:(NSNotification *)notification
{
    NSString *path = [toPaginate objectAtIndex:0];
    [EucBookPageIndex markBookBundleAsIndexConstructed:path];
    NSLog(@"Pagination complete for %@", path);
    
    [toPaginate removeObjectAtIndex:0];
                                  
    if(![self paginateNextBook]) {
        NSLog(@"Pagination done!");
        [toPaginate release];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:BookPaginationCompleteNotification object:paginator];
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
        for(NSString *resource in [[NSFileManager defaultManager] directoryContentsAtPath:resourcePath]) {
            NSString *fullPath = [resourcePath stringByAppendingPathComponent:resource];
            BOOL isDirectory = YES;
            if([[NSFileManager defaultManager] fileExistsAtPath:[fullPath stringByAppendingPathComponent:@"META-INF"] isDirectory:&isDirectory] && isDirectory) {
                [toPaginate addObject:fullPath];
            }
        }        
    
        paginator = [[EucBookPaginator alloc] init];        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(paginationComplete:)
                                                     name:BookPaginationCompleteNotification
                                                   object:paginator];
        
        [[NSFileManager defaultManager] removeItemAtPath:PAGINATION_PATH error:nil];
        [[NSFileManager defaultManager] createDirectoryAtPath:PAGINATION_PATH withIntermediateDirectories:YES attributes:nil error:nil];
        
        if([self paginateNextBook]) {
            self.paginationUnderway = YES;
        } else {
            [toPaginate release];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:BookPaginationCompleteNotification object:paginator];
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

