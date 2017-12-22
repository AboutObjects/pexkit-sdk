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

void composite(CGImageRef cgImage, CVPixelBufferRef pixelBuffer)
{
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    size_t length = CGImageGetWidth(cgImage) * CGImageGetHeight(cgImage);
    unsigned int *base = (unsigned int *)CVPixelBufferGetBaseAddress(pixelBuffer);
    
    for (int i = 0; i < length; i++)
    {
        // TODO: transfer pixels
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

void PerformOperationWithImagePixelData(CGImageRef cgImage, void (^operationToPerform)(void *data))
{
    // Create the bitmap context
    CGContextRef context = CreateARGBBitmapContext(cgImage);
    if (context == NULL)
    {
        fprintf(stderr, "Failed to create ARGB bitmap context\n");
        return;
    }
    
    // Get image width, height. We'll use the entire image.
    size_t w = CGImageGetWidth(cgImage);
    size_t h = CGImageGetHeight(cgImage);
    CGRect rect = {{0,0},{w,h}};
    
    // Draw the image to the bitmap context. Once we draw, the memory
    // allocated for the context for rendering will then contain the
    // raw image data in the specified color space.
    CGContextDrawImage(context, rect, cgImage);
    
    // Now we can get a pointer to the image data associated with the bitmap
    // context.
    void *data = CGBitmapContextGetData(context);
    if (data != NULL)
    {
        operationToPerform(data);
    }
    
    // When finished, release the context
    CGContextRelease(context);
    // Free image data memory for the context
    if (data)
    {
        free(data);
    }
}

CGContextRef CreateARGBBitmapContext(CGImageRef cgImage)
{
    // Get image width, height. We'll use the entire image.
    size_t pixelsWide = CGImageGetWidth(cgImage);
    size_t pixelsHigh = CGImageGetHeight(cgImage);
    
    // Declare the number of bytes per row. Each pixel in the bitmap in this
    // example is represented by 4 bytes; 8 bits each of red, green, blue, and
    // alpha.
    size_t bitmapBytesPerRow = (pixelsWide * 4);
    size_t bitmapByteCount   = (bitmapBytesPerRow * pixelsHigh);
    
    // Use the generic RGB color space.
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    if (colorSpace == NULL)
    {
        fprintf(stderr, "Error allocating color space\n");
        return NULL;
    }
    
    // Allocate memory for image data. This is the destination in memory
    // where any drawing to the bitmap context will be rendered.
    void *bitmapData = malloc(bitmapByteCount);
    if (bitmapData == NULL)
    {
        fprintf(stderr, "Memory not allocated!");
        CGColorSpaceRelease(colorSpace);
        return NULL;
    }
    
    // Create the bitmap context. We want pre-multiplied ARGB, 8-bits
    // per component. Regardless of what the source image format is
    // (CMYK, Grayscale, and so on) it will be converted over to the format
    // specified here by CGBitmapContextCreate.
    CGContextRef context = CGBitmapContextCreate(bitmapData,
                                                 pixelsWide,
                                                 pixelsHigh,
                                                 8,      // bits per component
                                                 bitmapBytesPerRow,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedFirst);
    if (context == NULL)
    {
        free(bitmapData);
        fprintf(stderr, "Context not created!");
    }
    
    // Make sure and release colorspace before returning
    CGColorSpaceRelease(colorSpace);
    
    return context;
}


