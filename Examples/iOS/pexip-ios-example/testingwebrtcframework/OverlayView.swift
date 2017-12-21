// Copyright (C) 2017 About Objects, Inc. All Rights Reserved.
// See LICENSE.txt for this project's licensing information.

import UIKit
import GLKit

public class OverlayView: UIView
{
    var image: UIImage?
    lazy var renderer = UIGraphicsImageRenderer(bounds: self.bounds)
    
    func updateImage() {
        image = renderer.image { layer.render(in: $0.cgContext) }
    }
}

extension OverlayView: GLKViewControllerDelegate
{
    /*
     Called during the first half of the animation cycle to allow execution of
     any computationally expensive code not directly related to drawing.
     */
    public func glkViewControllerUpdate(_ controller: GLKViewController) {
        updateImage()
    }
}

