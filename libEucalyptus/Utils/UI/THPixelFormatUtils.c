/*
 *  THPixelFormatUtils.c
 *  libEucalyptus
 *
 *  Created by James Montgomerie on 24/02/2011.
 *  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
 *
 */

#include "THPixelFormatUtils.h"
#include <stdint.h>

void convertPremultipliedRGBABitmapToNonpremultipliedRGBA4444Bitmap(void *premultipliedRGBABitmap, 
                                                                    size_t premultipliedRGBABitmapByteSize,
                                                                    void *nonpremultipliedRGBA4444BitmapOut)
{ 
    uint8_t *RGBATextureData = (uint8_t *)premultipliedRGBABitmap;        
    uint16_t *RGBA444TextureData = (uint16_t *)nonpremultipliedRGBA4444BitmapOut;        
    for(int i = 0; i < premultipliedRGBABitmapByteSize; i += 4) {
        uint16_t result = 0;
        uint32_t alpha = RGBATextureData[i+3];
        if(alpha) {
            result |= ((255 * (uint32_t)RGBATextureData[i]) / alpha) >> 4;
            result <<= 4;
            result |= ((255 * (uint32_t)RGBATextureData[i+1]) / alpha) >> 4; 
            result <<= 4; 
            result |= ((255 * (uint32_t)RGBATextureData[i+2]) / alpha) >> 4;
            result <<= 4;
            result |= alpha >> 4;
        }
        RGBA444TextureData[i / 4] = result;
    }
}

void convertRGBABitmapToRGB565Bitmap(void *RGBABitmap, 
                                     size_t RGBABitmapByteSize,
                                     void *RGB565BitmapOut)
{
    uint8_t *RGBATextureData = (uint8_t *)RGBABitmap;        
    uint16_t *RGB565TextureData = (uint16_t *)RGB565BitmapOut;        
    for(int i = 0; i < RGBABitmapByteSize; i += 4) {
        uint16_t result = 0;
        result |= RGBATextureData[i] >> 3;
        result <<= 6;
        result |= RGBATextureData[i+1] >> 2; 
        result <<= 5; 
        result |= RGBATextureData[i+2] >> 3;
        RGB565TextureData[i / 4] = result;
    }    
}