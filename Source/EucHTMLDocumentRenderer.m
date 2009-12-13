//
//  EucHTMLDocumentRenderer.m
//  LibCSSTest
//
//  Created by James Montgomerie on 13/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import "EucHTMLDocumentRenderer.h"


@implementation EucHTMLDocumentRenderer



- (void)layout
{
/*
    While we have subnodes
        If subnode is block
            If line has contents, start new line.
        If subnode is inline
            While subnodes are inline and not float
                Combine contents and perform whitespace processing.
                Need to be able to map from processed words back
                to their original nodes for sizing and rendering purposes.
            Create horizontally-sized valid-break structure.
                // Remember to take into account indentation and any contents
                // already on the line.
            Justify resulting paragraph.
                Can we save the placement of the words at this point?]
                need to take into account baseline...
                Don't think it's possible, since we may need to expand the 
                line height based on ontent after a float. 
            If last line is over page return page done code (with place).
        Else if subnode is float
            Recurse to lay out float in available width.
            -- No need to worry about block vs. inline - that's 
            -- taken care of already.
            If resulting float is smaller than available width
                Place resulting float on current line.
            Else
                Place resulting float on next line.
        Else if subnode is block
            Start new line
            Recurse with block in available width.
 
    At what points can we test to see if we're over the requisite height?
    after each justification?  May give false-negaties (but that's okay - we'll
    re-process the line after completing the float).
*/
}


@end
