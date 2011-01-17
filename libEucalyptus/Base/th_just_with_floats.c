/*
 *  th_just_with_floats.c
 *  Eucalyptus
 *
 *  Created by James Montgomerie on 01/10/2008.
 *  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
 *
 */

#include "th_just_with_floats.h"
#include "stdio.h"
#include "stdlib.h"
#include "stdbool.h"
#include "limits.h"
#include "string.h"
#include "assert.h"

#include <Accelerate/Accelerate.h>

// This algorithm calculates paragraph breaks while trying to ensure that no
// single line it too far from the ideal length.  This is similar to how TeX's 
// line breaking works.  The interface is inspired by the LibHnj interface, 
// which I was using before but found hard to modify to do things like 
// hard-breaks.

// The idea here is to use Dijkstra's single-source shortest path algorithm
// to find the 'path' of breaks through a paragraph that will give a paragraph
// with the smallest total 'distance', where the distance between two breaks is
// defined as the deviation of the line they would create from the ideal line
// length.  The deviation is the square of the difference between the ideal 
// line length and the actual line length that using the two breaks would 
// create.

// A penalty can be assigned to using a break, this is treated as extra distance
// and added to the line length before calculating the deviation (so think of
// it as 'virtual pixels' that using the break adds to the line).

// Dijkstra's algorithm is largely as described in Cormen, Leiserson and 
// Rivest's "Introduction to Algorithms" (edition 1).

struct Estimates {
    CGFloat shortest_path_estimate;
    int predecessor;
    int examined;
};

static int extract_min(struct Estimates *estimates, vDSP_Length count, CGFloat *shortest_path_vector)
{
    CGFloat smallest_estimate_found;
    vDSP_Length smallest_index;
    
#if !CGFLOAT_IS_DOUBLE
    if(&vDSP_minvi != NULL) { // Check for the function's existence - it's 4.0+ and we support 3.2
        vDSP_minvi(shortest_path_vector,
                   1,
                   &smallest_estimate_found,
                   &smallest_index,
                   count); 
#else
    if(&vDSP_minviD != NULL) { // Check for the function's existence - it's 4.0+ and we support 3.2
        vDSP_minviD(shortest_path_vector,
                    1,
                    &smallest_estimate_found,
                    &smallest_index,
                    count);
#endif
    } else {
        smallest_index = 0;
        
        // Using indexes in here, as opposed to keeping a track of the current
        // best shortest_path_vector[smallest_index] in a variable, provides
        // a ~2% speedup, unintuitively.  Perhaps the compiler can optimize 
        // more easily?
        for(vDSP_Length i = 0; i < count; ++i) { 
            if(shortest_path_vector[i] < shortest_path_vector[smallest_index]) {
                smallest_index = i;
            }      
        }
        
        smallest_estimate_found = shortest_path_vector[smallest_index];
    }
    
    if(smallest_estimate_found != CGFLOAT_MAX) {
        estimates[smallest_index].examined = true;
        shortest_path_vector[smallest_index] = CGFLOAT_MAX;
        return (int)smallest_index;
    } else {
        return -1;
    }
}

static CGFloat calculate_weight(int from_break_index, int to_break_index, const THBreak *breaks, int count, CGFloat offset, CGFloat ideal_width, CGFloat two_hyphen_penalty) 
{
    CGFloat weight = CGFLOAT_MAX;
    
    CGFloat line_start = from_break_index == -1 ? -offset : breaks[from_break_index].x1;
    CGFloat line_end = breaks[to_break_index].x0;
    
    CGFloat line_width = line_end - line_start;
    if(ideal_width >= line_width) {
        if((breaks[to_break_index].flags & TH_JUST_WITH_FLOATS_FLAG_ISHARDBREAK) != 0) {
            weight = 0.0f;
        } else {
            weight = ideal_width - line_width + breaks[to_break_index].penalty;
            if(from_break_index != -1 &&
               (breaks[from_break_index].flags & TH_JUST_WITH_FLOATS_FLAG_ISHYPHEN) != 0 &&
               (breaks[to_break_index].flags & TH_JUST_WITH_FLOATS_FLAG_ISHYPHEN) != 0) {
                weight += two_hyphen_penalty;
            }
            weight *= weight;
        }
    }
    
    return weight;
}

static void relax_reachable_from(int break_u, const THBreak *breaks, struct Estimates *estimates, int count, CGFloat offset, CGFloat ideal_width, CGFloat two_hyphen_penalty, CGFloat *shortest_path_vector) 
{
    CGFloat break_u_estimate = (break_u == -1 ? 0 : estimates[break_u].shortest_path_estimate);
    bool found_a_break = false;
    for(int break_v = break_u + 1; break_v < count; ++break_v) {
        CGFloat weight_from_u_to_v = calculate_weight(break_u, break_v, breaks, count, offset, ideal_width, two_hyphen_penalty);
        if(weight_from_u_to_v < CGFLOAT_MAX) {
            CGFloat total_weight_to_v = break_u_estimate + weight_from_u_to_v;
            if(estimates[break_v].shortest_path_estimate > total_weight_to_v) {
                estimates[break_v].shortest_path_estimate = total_weight_to_v;
                estimates[break_v].predecessor = break_u;
                if(!estimates[break_v].examined) {
                    shortest_path_vector[break_v] = total_weight_to_v;
                }
            }
            found_a_break = true;
            if(weight_from_u_to_v == 0) {
                // We've found an ideal break (possibly a forced break),
                // so no breaks after it will be reachable.
                break;
            }
        } else {
            // This break was too far away, so no breaks after it will be 
            // reachable either.
            break;
        }
    }
    if(!found_a_break && break_u + 1 < count) {
        // If nothing was reachable it means that there's no possible way to 
        // make a line short enough.  We just break on the next break (leaving
        // a too-long line, but there's nothing we can do).
        estimates[break_u + 1].shortest_path_estimate = break_u_estimate;
        estimates[break_u + 1].predecessor = break_u;
        if(!estimates[break_u + 1].examined) {
            shortest_path_vector[break_u + 1] = break_u_estimate;
        }
        
    }
}

int th_just_with_floats(const THBreak *breaks, int break_count, CGFloat offset, CGFloat ideal_width, CGFloat two_hyphen_penalty, int *result) 
{
    struct Estimates *estimates = malloc(sizeof(struct Estimates) * break_count);
    for(int i = 0; i < break_count; ++i) {
        estimates[i].shortest_path_estimate = CGFLOAT_MAX;
        //estimates[i].predecessor = 0; // Doesn't matter if this is garbage, it will get filled in later.
        estimates[i].examined = false;
    }
    
    // This vector cotains the shortest path etiated for the /unvisited/
    // nodes.  A node's estimate in here is re-set to CGFLOAT_MAX when it is 
    // visited.  It's used so that we can use vector functions in extract_min
    // to find the minimum estimate for an unvisited node.
    size_t shortest_path_vector_length = sizeof(CGFloat) * break_count;
    CGFloat *shortest_path_vector = malloc(shortest_path_vector_length);
    const CGFloat to_fill_with = CGFLOAT_MAX;
    
#if !CGFLOAT_IS_DOUBLE
    memset_pattern4(shortest_path_vector, &to_fill_with, shortest_path_vector_length);
#else
    memset_pattern8(shortest_path_vector, &to_fill_with, shortest_path_vector_length);
#endif    
    
    // The meat of Dijkstra's algorithm:
    int examining_break = -1;
    do {
        relax_reachable_from(examining_break, breaks, estimates, break_count, offset, ideal_width, two_hyphen_penalty, shortest_path_vector);
        examining_break = extract_min(estimates, break_count, shortest_path_vector);
    } while(examining_break != -1);
    
    // Now we've calculated the minimum-weight path to the end of the paragraph,
    // we need to read it out of the estimates structure backwards.
    int used_break_count = 0;
    for(examining_break = break_count - 1; examining_break > -1; examining_break = estimates[examining_break].predecessor) {
        ++used_break_count;
    }
    
    examining_break = break_count - 1;
    for(int i = used_break_count - 1; i >= 0; --i) {
        result[i] = examining_break;
        examining_break = estimates[examining_break].predecessor;
    }
    
    /*
    for(int i = 0; i < break_count; ++i) {
        printf("%d: %8d %8d %d\n", i, estimates[i].shortest_path_estimate, estimates[i].predecessor, estimates[i].examined);
    }
    */
    
    free(estimates);
    free(shortest_path_vector);
        
    return used_break_count;
}

