#import <Foundation/Foundation.h>

#include <hubbub/hubbub.h>
#include <libcss/libcss.h>

#include "EucHTMLDocument.h"
#include "EucHTMLDocumentNode.h"
#include "EucHTMLDocumentConcreteNode.h"
#include "EucHTMLLayouter.h"
#include "EucHTMLRenderer.h"
#include "EucHTMLLayoutPositionedBlock.h"

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

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

    EucHTMLDocument *document = [[EucHTMLDocument alloc] initWithPath:[NSString stringWithUTF8String:argv[2]]];
    
    EucHTMLLayouter *layouter = [[EucHTMLLayouter alloc] init];
    layouter.document = document;
    CGRect frame = CGRectMake(0, 0, 320, CGFLOAT_MAX);
    EucHTMLLayoutPositionedBlock *positionedBlock = [layouter layoutFromNodeWithId:document.body.key
                                                                        wordOffset:0
                                                                      hyphenOffset:0
                                                                           inFrame:frame];
    [layouter release];
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    CGContextRef renderingContext = CGBitmapContextCreate(NULL,
                                                          positionedBlock.frame.size.width,
                                                          positionedBlock.frame.size.height,
                                                          8,
                                                          positionedBlock.frame.size.width * 4,
                                                          colorSpace, 
                                                          kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    
    EucHTMLRenderer *renderer = [[EucHTMLRenderer alloc] init];
    renderer.cgContext = renderingContext;
    [renderer render:positionedBlock];
    [renderer release];
        
    CGImageRef image = CGBitmapContextCreateImage(renderingContext);
    CGContextRelease(renderingContext);
    
    CGImageDestinationRef pngDestination = CGImageDestinationCreateWithURL((CFURLRef)[NSURL fileURLWithPath:@"/tmp/rendered.png"], 
                                                                           kUTTypePNG, 
                                                                           1, 
                                                                           NULL);
    CGImageDestinationAddImage(pngDestination, image, NULL);
    CGImageDestinationFinalize(pngDestination);
    CFRelease(pngDestination);
    CGImageRelease(image);
                                     
    [document release];
    
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
