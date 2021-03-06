// Copyright (C) 2017 About Objects, Inc. All Rights Reserved.
// See LICENSE.txt for this project's licensing information.

#import <WebRTC/WebRTC.h>
//#import "testingwebrtcframework-Swift.h"


@class OverlayView;

@interface IronBowVideoView: RTCEAGLVideoView

@property (strong, nonatomic) EAGLContext *eaglContext;
@property (strong, nonatomic) CIContext *ciContext;
@property (strong, nonatomic) IBOutlet OverlayView *overlayView;

@end
