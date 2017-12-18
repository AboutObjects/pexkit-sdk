// Copyright (C) 2017 About Objects, Inc. All Rights Reserved.
// See LICENSE.txt for this project's licensing information.

#import "IronBowVideoView.h"
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface RTCEAGLVideoView (IronBowAdditions)
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect;
@end

@interface IronBowVideoView ()
@property (assign, nonatomic) int count;
@end

@implementation IronBowVideoView

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [super glkView:view drawInRect:rect];
    self.count++;
    if (self.count < 3) NSLog(@"In %s", __func__);
}

@end
