#import <Foundation/Foundation.h>

#import <libcss/libcss.h>

#import "EucCSSInternal.h"

#import "EucCSSXMLTree.h"

#import "EucCSSIntermediateDocument.h"
#import "EucCSSIntermediateDocumentNode.h"
#import "EucCSSIntermediateDocumentConcreteNode.h"
#import "EucCSSLayouter.h"
#import "EucCSSRenderer.h"
#import "EucCSSLayoutPositionedBlock.h"

#import "THLog.h"
#import "THTimer.h"

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    THProcessLoggingDefaults();
    
    bool cssInitialised = false;

    css_error cssErr = css_initialise(argv[1], EucRealloc, NULL);
    if(cssErr != CSS_OK) {
        NSLog(@"Error \"%s\" setting up libCSS", css_error_to_string(cssErr));
        goto bail;
    } else {
       cssInitialised = YES;
    }    
        
    NSData *xmlData = [[NSData alloc] initWithContentsOfMappedFile:[NSString stringWithUTF8String:argv[3]]];
    EucCSSXMLTree *xmlTree = [[EucCSSXMLTree alloc] initWithData:xmlData];
    [xmlData release];
    
    EucCSSIntermediateDocument *document = [[EucCSSIntermediateDocument alloc] initWithDocumentTree:xmlTree
                                                                                        baseCSSPath:[NSString stringWithUTF8String:argv[2]]];
    
    EucCSSLayouter *layouter = [[EucCSSLayouter alloc] init];
    layouter.document = document;
    CGRect frame = CGRectMake(0, 0, 320, 480);
    EucCSSLayoutPoint layoutPoint = { 0, 0, 0 };
    BOOL completed = NO;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    CGContextRef renderingContext = CGBitmapContextCreate(NULL,
                                                          frame.size.width,
                                                          frame.size.height,
                                                          8,
                                                          frame.size.width * 4,
                                                          colorSpace, 
                                                          kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, frame.size.height);
    CGContextConcatCTM(renderingContext, flipVertical);    
    
    EucCSSRenderer *renderer = [[EucCSSRenderer alloc] init];
    renderer.cgContext = renderingContext;

    NSUInteger pageCount = 0;
    while(/*pageCount < 3 && */!completed) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        ++pageCount;
        THLog(@"Page %ld", pageCount);
        EucCSSLayoutPositionedBlock *positionedBlock = [layouter layoutFromPoint:layoutPoint
                                                                          inFrame:frame
                                                               returningNextPoint:&layoutPoint
                                                               returningCompleted:&completed];
        
        CGContextSaveGState(renderingContext);
        const CGFloat white[4]  = { 1.0f, 1.0f, 1.0f, 1.0f };
        CGContextSetFillColor(renderingContext, white);
        CGContextFillRect(renderingContext, frame);
        CGContextRestoreGState(renderingContext);
        
        [renderer render:positionedBlock];
            
        CGImageRef image = CGBitmapContextCreateImage(renderingContext);
        
        CGImageDestinationRef pngDestination = CGImageDestinationCreateWithURL((CFURLRef)[NSURL fileURLWithPath:[NSString stringWithFormat:@"/tmp/rendered%ld.png", (long)pageCount]], 
                                                                               kUTTypePNG, 
                                                                               1, 
                                                                               NULL);
        CGImageDestinationAddImage(pngDestination, image, NULL);
        CGImageDestinationFinalize(pngDestination);
        CFRelease(pngDestination);
        CGImageRelease(image);
        
        [pool drain];
    }      
    [renderer release];
    CGContextRelease(renderingContext);
    [layouter release];
    [document release];
    
    [xmlTree release];

bail:
    if(cssInitialised) {
        css_finalise(EucRealloc, NULL);
    }
    
    [pool drain];
    return 0;
}
