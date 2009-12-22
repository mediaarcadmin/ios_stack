//
//  MockBook.m
//  LibraryView
//
//  Created by matt on 15/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import "BlioMockBook.h"

@implementation BlioMockBook

@synthesize title;
@synthesize author;
@synthesize coverPath;
@synthesize bookPath;
@synthesize pdfPath;

- (void)dealloc {
  self.title = nil;
  self.author = nil;
  self.coverPath = nil;
  self.bookPath = nil;
  self.pdfPath = nil;
  [super dealloc];
}

- (UIImage *)coverImage {
  return [UIImage imageWithContentsOfFile:self.coverPath];
}

@end
