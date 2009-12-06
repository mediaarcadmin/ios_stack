#import <Foundation/Foundation.h>

#include <hubbub/hubbub.h>
#include <hubbub/parser.h>
#include <libcss/libcss.h>

#include "EucHTDBCreation.h"

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    BOOL cssInitialised = NO;
    BOOL hubbubInitialised = NO;
    const ssize_t chunkSize = 4096;
    uint8_t buffer[chunkSize];

    css_error cssErr = css_initialise(argv[1], EucRealloc, NULL);
    if(cssErr != CSS_OK) {
        NSLog(@"Error \"%s\" setting up libCSS", css_error_to_string(cssErr));
        goto bail;
    } else {
        cssInitialised = YES;
    }    
    
    hubbub_error err;
    err = hubbub_initialise(argv[1], EucRealloc, NULL);
    if(err != HUBBUB_OK) {
        NSLog(@"Error \"%s\" setting up hubbub", hubbub_error_to_string(err));
        goto bail;
    } else {
        hubbubInitialised = YES;
    }

    EucHTDB *context = EucHTDBOpen("/tmp/test.db", O_CREAT | O_RDWR | O_TRUNC);
        
    FILE *fp = fopen(argv[2], "rb");
	if (fp == NULL) {
		printf("Failed opening %s\n", argv[2]);
		goto bail;
	}
    
    
    
    
    hubbub_parser *parser;
    err = hubbub_parser_create(NULL, true, EucRealloc, NULL, &parser);
    if(err != HUBBUB_OK) {
        fprintf(stderr, "Error \"%s\" creating parser\n", hubbub_error_to_string(err));
        goto bail;
    }
    
    hubbub_tree_handler *treeHandler = EucHTDBHubbubTreeHandlerCreateWithContext(context);
    
    hubbub_parser_optparams params;
	params.tree_handler = treeHandler;
	err = hubbub_parser_setopt(parser, HUBBUB_PARSER_TREE_HANDLER, &params);
    if(err != HUBBUB_OK) {
        fprintf(stderr, "Error \"%s\" setting HUBBUB_PARSER_TREE_HANDLER option on parser\n", hubbub_error_to_string(err));
        goto bail;
    }
    
    void *rootNodeP;
    EucHTDBCreateRoot(context, &rootNodeP);
    params.document_node = rootNodeP;
    err = hubbub_parser_setopt(parser, HUBBUB_PARSER_DOCUMENT_NODE, &params);
    if(err != HUBBUB_OK) {
        fprintf(stderr, "Error \"%s\" setting HUBBUB_PARSER_DOCUMENT_NODE option on parser\n", hubbub_error_to_string(err));
        goto bail;
    }
    
    size_t bytesRead = 0;
	for(;;) {
        bytesRead = fread(buffer, 1, chunkSize, fp);
        
        if(bytesRead < 1) {
            break;
        }
        
		err = hubbub_parser_parse_chunk(parser, buffer, bytesRead);
        if(err != HUBBUB_OK) {
            NSLog(@"Error \"%s\" during parse", hubbub_error_to_string(err));
            goto bail;
        }
	}

    hubbub_charset_source cssource = 0;
	const char *charset = hubbub_parser_read_charset(parser, &cssource);
    
	NSLog(@"Charset: %s (from %d)\n", charset, cssource);    
    Traverse(context);

    
bail:
    if(fp) {
        fclose(fp);
    }
    if(parser) {
        hubbub_parser_destroy(parser);
    }
    if(treeHandler) {
        free(treeHandler);
    }
    EucHTDBClose(context);
    if(cssInitialised) {
        css_finalise(EucRealloc, NULL);
    }
    if(hubbubInitialised) {
        hubbub_finalise(EucRealloc, NULL);
    }
    
    [pool drain];
    return 0;
}
