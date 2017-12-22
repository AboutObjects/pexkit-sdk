// Copyright (C) 2017 About Objects, Inc. All Rights Reserved.
// See LICENSE.txt for this project's licensing information.

#import <Foundation/Foundation.h>
#import "CompositingVideoRenderer.h"

#import "testingwebrtcframework-Swift.h"

@interface CompositingVideoRenderer ()
@property (nonatomic) CGSize frameSize;
@end

@implementation CompositingVideoRenderer

- (OverlayView *)overlayView {
    return [ViewController reallyGlobalOverlayView];
}

- (void)renderFrame:(RTCVideoFrame *)frame
{
    [self compositeWithFrame: frame];
}

- (void)setSize:(CGSize)size {
    self.frameSize = size;
}

@end
