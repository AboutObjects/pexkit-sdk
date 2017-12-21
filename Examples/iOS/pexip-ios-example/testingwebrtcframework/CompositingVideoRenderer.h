// Copyright (C) 2017 About Objects, Inc. All Rights Reserved.
// See LICENSE.txt for this project's licensing information.

#import <Foundation/Foundation.h>
#import <WebRTC/WebRTC.h>

@class OverlayView;

@interface CompositingVideoRenderer: NSObject <RTCVideoRenderer>

@property (strong, nonatomic) IBOutlet OverlayView *overlayView;

@end

