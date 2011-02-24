/*
 *  THPixelFormatUtils.h
 *  libEucalyptus
 *
 *  Created by James Montgomerie on 24/02/2011.
 *  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
 *
 */

#include <sys/types.h>

void convertPremultipliedRGBABitmapToNonpremultipliedRGBA4444Bitmap(void *premultipliedRGBABitmap, 
                                                                    size_t premultipliedRGBABitmapByteSize,
                                                                    void *nonpremultipliedRGBA4444BitmapOut);
void convertRGBABitmapToRGB565Bitmap(void *RGBABitmap, 
                                     size_t RGBABitmapByteSize,
                                     void *RGB565BitmapOut);