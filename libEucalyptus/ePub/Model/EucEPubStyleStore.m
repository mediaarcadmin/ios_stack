//
//  EucEPubStyleStore.m
//  libEucalyptus
//
//  Created by James Montgomerie on 25/07/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import "EucEPubStyleStore.h"
#import "EucBookTextStyle.h"
#import "css21Lexer.h"
#import "css21Parser.h"
#import "THLog.h"

@implementation EucEPubStyleStore

- (id)init 
{
    if((self = [super init])) {
        _selectorToStyle = [[NSMutableDictionary alloc] init];        
    }
    return self;
}

- (void)dealloc 
{
    [_selectorToStyle release];
    [super dealloc];
}

static void printTree(pANTLR3_BASE_TREE tree, int indent)
{
    for(int i = 0; i < indent; ++i) {
        putchar(' ');
    }
    pANTLR3_STRING string = NULL;
    pANTLR3_COMMON_TOKEN token = tree->getToken(tree);
    if(token) {
        string = token->toString(token);
    }
    if(string) {
        printf("- %d: %s", tree->getType(tree), string->chars);
    } else {
        printf("| %d", tree->getType(tree));
    }
    putchar('\n');
    for(int i = 0; i < tree->getChildCount(tree); ++i) {
        printTree(tree->getChild(tree, i), indent+1);
    }
}

- (NSString *)_stringByCollapsingTokens:(pANTLR3_BASE_TREE)tree
{
    NSMutableString *ret = [NSMutableString string];
    
    ANTLR3_UINT32 childCount = tree->getChildCount(tree);
    for(ANTLR3_UINT32 i = 0; i < childCount; ++i) {
        pANTLR3_BASE_TREE node = tree->getChild(tree, i);
        pANTLR3_STRING string = node->toString(node);
        if(string) {
            [ret appendString:[NSString stringWithUTF8String:(const char *)string->chars]];
        } else {
            THWarn(@"Unexpected token with no string while collapsing tokens");
        }
    }
    
    return ret.length ? ret : nil;
}

- (void)_addStylesForDeclarationList:(pANTLR3_BASE_TREE)tree toStyle:(EucBookTextStyle *)style
{
    ANTLR3_UINT32 childCount = tree->getChildCount(tree);
    for(ANTLR3_UINT32 i = 0; i < childCount; ++i) {
        pANTLR3_BASE_TREE node = tree->getChild(tree, i);

        pANTLR3_BASE_TREE propertyNode = node->getFirstChildWithType(node, PROPERTY);
        pANTLR3_BASE_TREE valueNode = node->getFirstChildWithType(node, VALUE);
        pANTLR3_BASE_TREE priorityNode = node->getFirstChildWithType(node, IMPORTANT);
        
        if(propertyNode && valueNode) {
            NSString *property = [self _stringByCollapsingTokens:propertyNode];
            NSString *value = [self _stringByCollapsingTokens:valueNode];

            [style setStyle:property to:value];
        }
        
        if(priorityNode) {
            THWarn(@"Ignoring rule priority");
        }
    }   
}

- (void)_addRuleset:(pANTLR3_BASE_TREE)tree
{
    NSMutableArray *selectors = [[NSMutableArray alloc] init];
    
    ANTLR3_UINT32 childCount = tree->getChildCount(tree);
    ANTLR3_UINT32 childCursor = 0;
    
    pANTLR3_BASE_TREE node;
    while(childCursor < childCount) {
        node = tree->getChild(tree, childCursor);
        if(node->getType(node) != SELECTOR) {
            break;
        }
        NSString *selector = [self _stringByCollapsingTokens:node];
        if(selector) {
            [selectors addObject:selector];
        } else {
            THWarn(@"Unexpected empty CSS selector");
        }
        ++childCursor;
    } 
    if(![selectors count]) {
        THWarn(@"No selectors in CSS ruleset");
    } else {
        while(childCursor < childCount) {
            node = tree->getChild(tree, childCursor);
            if(node->getType(node) != DECLARATIONLIST) {
                THWarn(@"Unexpected node of tyle %ld encountered in ruleset", (long)node->getType(node));
            } else {
                for(NSString *selector in selectors) {
                    EucBookTextStyle *style = [_selectorToStyle objectForKey:selector];
                    if(!style) {
                        style = [[EucBookTextStyle alloc] init];
                        [_selectorToStyle setObject:style forKey:selector];
                        [style release];
                    }
                    [self _addStylesForDeclarationList:node toStyle:style];
                }
            }
            ++childCursor;
        }
    }
    
    [selectors release];
}

- (void)_addStyleSheet:(pANTLR3_BASE_TREE)tree
{
    if(tree) {
        ANTLR3_UINT32 childCount = tree->getChildCount(tree);
        for(ANTLR3_UINT32 i = 0; i < childCount; ++i) {
            pANTLR3_BASE_TREE node = tree->getChild(tree, i);
            switch(node->getType(node)) {
                case CHARSET:
                    THWarn(@"CSS @charset not (yet?) supported");
                    break;
                case IMPORT:
                    THWarn(@"CSS @import not (yet?) supported");
                    break;
                case RULESET:
                    [self _addRuleset:node];
                    break;
                default:
                    THWarn(@"Unexpected token encountered in CSS");
                    break;
            }
        }

        //printTree(tree, 0);
        //THLog(@"Parsed stylesheet %ld children", (long)childCount);
        //THLog(@"%@", _selectorToStyle);
        //fflush(stdout);
    }
}

- (void)addStylesFromCSSFile:(NSString *)path
{
    NSData *data = [NSData dataWithContentsOfMappedFile:path];
    
    pANTLR3_INPUT_STREAM inputStream = antlr3NewAsciiStringInPlaceStream((pANTLR3_UINT8)[data bytes], [data length], (pANTLR3_UINT8)path);
    if(inputStream) {
        pcss21Lexer lexer = css21LexerNew(inputStream);
        if(lexer) {
            pANTLR3_COMMON_TOKEN_STREAM tokenStream = antlr3CommonTokenStreamSourceNew(ANTLR3_SIZE_HINT, TOKENSOURCE(lexer));
            if(tokenStream) {
                pcss21Parser parser = css21ParserNew(tokenStream);
                if(parser) {
                    css21Parser_styleSheet_return styleSheet = parser->styleSheet(parser);

                    [self _addStyleSheet:styleSheet.tree];

                    parser->free(parser);
                }
                tokenStream->free(tokenStream);
            }
            lexer->free(lexer);
        }
        inputStream->close(inputStream);
    }
}

- (EucBookTextStyle *)styleWithInlineStyleDeclaration:(char *)inlineStyleDeclaration fromStyle:(EucBookTextStyle *)style
{    
    EucBookTextStyle *ret = [style copy];
    pANTLR3_INPUT_STREAM inputStream = antlr3NewAsciiStringInPlaceStream((pANTLR3_UINT8)inlineStyleDeclaration, strlen(inlineStyleDeclaration), (pANTLR3_UINT8)"");
    if(inputStream) {
        pcss21Lexer lexer = css21LexerNew(inputStream);
        if(lexer) {
            pANTLR3_COMMON_TOKEN_STREAM tokenStream = antlr3CommonTokenStreamSourceNew(ANTLR3_SIZE_HINT, TOKENSOURCE(lexer));
            if(tokenStream) {
                pcss21Parser parser = css21ParserNew(tokenStream);
                if(parser) {
                    css21Parser_declarationList_return declarations = parser->declarationList(parser);
                    
                    [self _addStylesForDeclarationList:declarations.tree toStyle:ret];
                    
                    parser->free(parser);
                }
                tokenStream->free(tokenStream);
            }
            lexer->free(lexer);
        }
        inputStream->close(inputStream);
    }    
    return [ret autorelease];
}

- (EucBookTextStyle *)styleForSelector:(NSString *)selector fromStyle:(EucBookTextStyle *)style
{
    // Might be wser to have this store simple selectors, and look up by 
    // selecto (with info on position etc), merging outside.
    EucBookTextStyle *newStyle = [_selectorToStyle objectForKey:selector]; 
    if(!style) {
        return newStyle;
    } else {
        if(newStyle) {
            return [style styleByCombiningStyle:newStyle];
        } else {
            return style;
        }
    }
}

@end
