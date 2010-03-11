#import <Foundation/Foundation.h>

#import <hubbub/hubbub.h>
#import <libcss/libcss.h>

#import "EucCSSInternal.h"

#import "EucHTMLDB.h"
#import "EucHTMLDBCreation.h"
#import "EucHTMLDBNodeManager.h"

#import "EucCSSIntermediateDocument.h"
#import "EucCSSIntermediateDocumentNode.h"
#import "EucCSSIntermediateDocumentConcreteNode.h"
#import "EucCSSLayouter.h"
#import "EucCSSRenderer.h"
#import "EucCSSLayoutPositionedBlock.h"

#import "THLog.h"

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    THProcessLoggingDefaults();
    
    bool cssInitialised = false;
    bool hubbubInitialised = false;

    css_error cssErr = css_initialise(argv[1], EucRealloc, NULL);
    if(cssErr != CSS_OK) {
        NSLog(@"Error \"%s\" setting up libCSS", css_error_to_string(cssErr));
        goto bail;
    } else {
       cssInitialised = YES;
    }    
    
    hubbub_error hubbubErr = hubbub_initialise(argv[1], EucRealloc, NULL);
    if(hubbubErr != HUBBUB_OK) {
        fprintf(stderr, "Error \"%s\" setting up hubbub\n", hubbub_error_to_string(hubbubErr));
        goto bail;
    } else {
        hubbubInitialised = true;
    }
    
    EucHTMLDB *htmlDb = EucHTMLDBCreateWithHTMLAtPath(argv[2], NULL);

    Traverse(htmlDb);
    
    lwc_context *lwcContext;
    lwc_create_context(EucRealloc, NULL, &lwcContext);
    lwc_context_ref(lwcContext);
    
    EucHTMLDBNodeManager *htmlDbManager = [[EucHTMLDBNodeManager alloc] initWithHTMLDB:htmlDb
                                                                           lwcContext:lwcContext];
    
    EucCSSIntermediateDocument *document = [[EucCSSIntermediateDocument alloc] initWithDocumentTree:htmlDbManager
                                                                                         lwcContext:lwcContext];

        
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
    [htmlDbManager release];
    lwc_context_unref(lwcContext);
    EucHTMLDBClose(htmlDb);
    
bail:
    if(cssInitialised) {
        css_finalise(EucRealloc, NULL);
    }
    if(hubbubInitialised) {
        hubbub_finalise(EucRealloc, NULL);
    }
    
    [pool drain];
    return 0;
}
