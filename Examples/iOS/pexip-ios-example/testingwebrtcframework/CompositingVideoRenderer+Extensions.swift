// Copyright (C) 2017 About Objects, Inc. All Rights Reserved.
// See LICENSE.txt for this project's licensing information.

// Copyright (C) 2017 About Objects, Inc. All Rights Reserved.
// See LICENSE.txt for this project's licensing information.

import UIKit
import AVFoundation
import GLKit

// TODO: Migrate to class...
var eaglContext = EAGLContext.init(api: .openGLES3)
var ciContext = CIContext(eaglContext: eaglContext!, options: [kCIContextWorkingColorSpace: NSNull()])

extension CompositingVideoRenderer
{
    public func composite(frame: RTCVideoFrame?) {
        guard let frame = frame else { return }
        var image = CIImage(cvPixelBuffer: frame.nativeHandle, options: nil)
        overlayView.updateImage()
        image = image.composited(with: overlayView.image)
        frame.convertBufferIfNeeded()
    }
}

extension CIImage
{
    func composited(with image: UIImage?) -> CIImage {
        if
            let overlayImage = image,
            let overlay = CIImage(image: overlayImage)?.applying(CGAffineTransform(scaleX: 0.5, y: 0.5)) {
            return overlay.compositingOverImage(self)
        }
        return CIImage()
    }
}

