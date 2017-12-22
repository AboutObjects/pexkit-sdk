// Copyright (C) 2017 About Objects, Inc. All Rights Reserved.
// See LICENSE.txt for this project's licensing information.

import UIKit
import AVFoundation
import GLKit

extension IronBowVideoView
{
    var glkView: GLKView? {
        return value(forKey: "_glkView") as? GLKView
    }
    
//    open override func renderFrame(_ frame: RTCVideoFrame?) {
////        super.renderFrame(frame)
//        guard let cvPixelBuffer = frame?.nativeHandle else { return }
//        draw(buffer: cvPixelBuffer)
//    }
    
    
    private func draw(buffer: CVImageBuffer) {
        guard let glkView = self.glkView else { return }
        glkView.bindDrawable()

        if eaglContext != EAGLContext.current() { EAGLContext.setCurrent(self.eaglContext) }

        var image = CIImage(cvPixelBuffer: buffer, options: nil) //.oriented(forExifOrientation: orientation(connection))
        
        overlayView.updateImage()
        
        if let overlayImage = overlayView.image,
            let overlay = CIImage(image: overlayImage)?.applying(CGAffineTransform(scaleX: 0.5, y: 0.5)) {
            image = overlay.compositingOverImage(image)
        }
        let drawableBounds = CGRect(origin: .zero, size: CGSize(width: glkView.drawableWidth, height: glkView.drawableHeight))
        ciContext.draw(image, in: drawableBounds, from: image.extent)

        // TODO: not sure we need this
        glkView.display()
    }
}
