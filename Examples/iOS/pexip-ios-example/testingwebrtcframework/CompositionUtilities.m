// Copyright (C) 2017 About Objects, Inc. All Rights Reserved.
// See LICENSE.txt for this project's licensing information.

#import "CompositionUtilities.h"

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
//#import <CoreMedia/CoreMedia.h>

void composeVideoWithImage(CMSampleBufferRef sampleBuffer, CIImage *image)
{
    
}

void composeVideo(CMSampleBufferRef sampleBuffer)
{
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    unsigned char *base = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    unsigned char *pixel;
    
    for (int row = 0; row < 500; row += 8) {
        for (int col = 0; col < CVPixelBufferGetWidth(pixelBuffer); col += 8) {
            pixel = base + row * CVPixelBufferGetBytesPerRow(pixelBuffer) + col * 4;
            pixel[0] = 100;
            pixel[1] = 100;
            pixel[2] = 100;
            pixel[3] = 255;
        }
    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}


