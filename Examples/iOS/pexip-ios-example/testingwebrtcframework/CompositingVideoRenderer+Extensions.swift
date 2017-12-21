// Copyright (C) 2017 About Objects, Inc. All Rights Reserved.
// See LICENSE.txt for this project's licensing information.

// Copyright (C) 2017 About Objects, Inc. All Rights Reserved.
// See LICENSE.txt for this project's licensing information.

import UIKit
import AVFoundation
import GLKit


var eaglContext = EAGLContext.init(api: .openGLES3)
var ciContext = CIContext(eaglContext: eaglContext!, options: [kCIContextWorkingColorSpace: NSNull()])

extension CompositingVideoRenderer
{
    public func composite(frame: RTCVideoFrame?) {
        guard let cvPixelBuffer = frame?.nativeHandle else { return }
        composite(buffer: cvPixelBuffer)
        frame?.convertBufferIfNeeded()
    }
    
    private func composite(buffer: CVImageBuffer) {
        var image = CIImage(cvPixelBuffer: buffer, options: nil)
        overlayView.updateImage()
        image = image.composited(with: overlayView.image)
        
        // And then a miracle happens!
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



//private func composite(buffer: CVImageBuffer) {
//    var image = CIImage(cvPixelBuffer: buffer, options: nil)
//    overlayView.updateImage()
//    image = image.composited(with: overlayView.image)
//
//    //        overlayView.updateImage()
//    //        if let overlayImage = overlayView.image,
//    //            let overlay = CIImage(image: overlayImage)?.applying(CGAffineTransform(scaleX: 0.5, y: 0.5)) {
//    //            image = overlay.compositingOverImage(image)
//    //        }
//
//    //        if eaglContext != EAGLContext.current() { EAGLContext.setCurrent(eaglContext) }
//    //        let drawableBounds = CGRect(origin: .zero, size: CGSize(width: 280, height: 220))
//    //        ciContext.draw(image, in: drawableBounds, from: image.extent)
//}


//    func composited(image: CIImage) -> CIImage {
//        overlayView.updateImage()
//        if let overlayImage = overlayView.image,
//            let overlay = CIImage(image: overlayImage)?.applying(CGAffineTransform(scaleX: 0.5, y: 0.5)) {
//            return overlay.compositingOverImage(image)
//        }
//        return image
//    }
