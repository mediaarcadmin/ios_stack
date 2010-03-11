/*
 *  th_just_with_floats.h
 *  Eucalyptus
 *
 *  Created by James Montgomerie on 01/10/2008.
 *  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
 *
 */

#ifndef __TH_JUST_WITH_FLOATS_H__
#define __TH_JUST_WITH_FLOATS_H__

#include <CoreGraphics/CGBase.h>

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

// These routines will break a paragraph up with line breaks giving a pleasingly
// spaced paragraph rather than just naively breaking each line when it gets too
// long (so, e.g., it might place a short word on the next line, even if it
// would fit on the current line, if doing so would make the paragraph spacing
// more even.    
    
// The interface is inspired (but not identical to) LibHnj's justification 
// interface.
    
// The algorithm is similar to the ne used in TeX (see source file for further
// details.

    
// These are here mostly for informational purposes.  At the moment, the
// only one actually used by the justifier logic is TH_JUST_WITH_FLOATS_FLAG_ISHARDBREAK.
#define TH_JUST_WITH_FLOATS_FLAG_ISSPACE     0x01
#define TH_JUST_WITH_FLOATS_FLAG_ISHYPHEN    0x02
#define TH_JUST_WITH_FLOATS_FLAG_ISTAB       0x04    
#define TH_JUST_WITH_FLOATS_FLAG_ISHARDBREAK 0x08

    
// A break is a point where the line could potentially break (space, hyphen 
// etc.)
// Lengths are given as the length of a logical line with no breaks before
// this break.
// Informally:
// 'x0' is the length of the line if this break is taken (so, e.g., for a 
//      space, includes the length of the preceeding word, but not the space; 
//      for a hyphen, includes the partial word and the hyphen length).
// 'x1' is the logical length of the line 'including' the break if the break is
//      /not/ taken (so, e.g., for a space, includes the length of the word and
//      the space; for a hyphen, includes the length of the whole word minus the
//      length of the word portion that would go on the next line).
// Formally:  
// 'x0' = break-taken-line-width, 
// 'x1' = break-taken-line-width + unbroken-line-width - 
//          (break-taken-line-width + portion-on-next-line-width)
// 'penalty' is an additional penalty for using this break.  Its units are the 
//      same units used for length (so, e.g., a penalty of '10' means that if 
//      this break is used, the algorithm judges the resulting line as being 
//      10 units further from the 'ideal' width than it really is).
// 'flags' are flags as described above.
typedef struct THBreak {
    CGFloat x0;
    CGFloat x1;
    CGFloat penalty;
    int flags;
} THBreak;

    
// Takes an array of potential break points (see above for definition of a 
// point), and calculates which points to use to make lines up to ideal_width
// in length.  The indexes of the breaks used are placed into the use-supplied
// result array.  The return value is number of used breaks.
// Note that the last break must have the flag TH_JUST_WITH_FLOATS_FLAG_ISHARDBREAK set,
// otherwise it will be used in the justification calculations (i.e. the 
// justifier will attempt to make it the same length as the other lines).
int th_just_with_floats(const THBreak *breaks, int break_count, CGFloat offset, CGFloat ideal_width, CGFloat two_hyphen_penalty, int *result);

#ifdef __cplusplus
}
#endif // __cplusplus

#endif // __TH_JUST_WITH_FLOATS_H__
