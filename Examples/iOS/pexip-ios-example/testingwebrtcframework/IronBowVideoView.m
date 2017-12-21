// Copyright (C) 2017 About Objects, Inc. All Rights Reserved.
// See LICENSE.txt for this project's licensing information.

#import "IronBowVideoView.h"
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <CoreImage/CoreImage.h>

#import "testingwebrtcframework-Swift.h"

@interface RTCEAGLVideoView (IronBowAdditions)
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect;
@end

@interface IronBowVideoView ()
@property (assign, nonatomic) int count;
@end

@implementation IronBowVideoView

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.eaglContext = [super valueForKey:@"glContext"];
}

- (CIContext *)ciContext {
    if (!_ciContext) {
        _ciContext = [CIContext contextWithEAGLContext:self.eaglContext options:@{ kCIContextWorkingColorSpace: NSNull.null }];
    }
    return _ciContext;
}

@end
