// Copyright (C) 2017 About Objects, Inc. All Rights Reserved.
// See LICENSE.txt for this project's licensing information.

#import <CoreMedia/CoreMedia.h>
#import <CoreImage/CoreImage.h>

void composeVideo(CMSampleBufferRef sampleBuffer);
void composeVideoWithImage(CMSampleBufferRef sampleBuffer, CIImage *image);

void PerformOperationWithImagePixelData(CGImageRef inImage, void (^operationToPerform)(void *data));
CGContextRef CreateARGBBitmapContext(CGImageRef inImage);


