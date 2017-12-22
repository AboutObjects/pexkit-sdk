// Copyright (C) 2017 About Objects, Inc. All Rights Reserved.
// See LICENSE.txt for this project's licensing information.

import UIKit
import GLKit

public class OverlayView: UIView
{
    @IBOutlet weak var pulseLabel: UILabel!
    @IBOutlet weak var spo2Label: UILabel!
    
    var image: UIImage?
    lazy var renderer = UIGraphicsImageRenderer(bounds: self.bounds)
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateImage()
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateMeasurements), userInfo: nil, repeats: true)
    }
    
    func updateImage() {
        DispatchQueue.main.async {
            self.image = self.renderer.image { self.layer.render(in: $0.cgContext) }
        }
    }
    
    @objc func updateMeasurements() {
        pulseLabel.text = "\(arc4random_uniform(6) + 57)"
        updateImage()
    }
}

//extension OverlayView: GLKViewControllerDelegate
//{
//    /*
//     Called during the first half of the animation cycle to allow execution of
//     any computationally expensive code not directly related to drawing.
//     */
//    public func glkViewControllerUpdate(_ controller: GLKViewController) {
//        updateImage()
//    }
//}

