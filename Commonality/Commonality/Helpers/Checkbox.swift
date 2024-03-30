//
//  Checkbox.swift
//  Commonality
//
//  Created by Thabo David Klass on 15/4/18.
//  Copyright © 2018 Spreebie, Inc. All rights reserved.
//

import Foundation
import UIKit

// This is an implimentation of a checkbox
class Checkbox: UIButton {
    // Images
    let checkedImage: UIImage = #imageLiteral(resourceName: "checkmark-selected")
    let uncheckedImage: UIImage = #imageLiteral(resourceName: "checkmark-unselected") 
    
    // Bool property
    var isChecked: Bool = false {
        didSet{
            if isChecked == true {
                self.setImage(checkedImage, for: UIControlState.normal)
            } else {
                self.setImage(uncheckedImage, for: UIControlState.normal)
            }
        }
    }
    
    override func awakeFromNib() {
        self.addTarget(self, action:#selector(touchUpInsideHandler(sender:)), for: UIControlEvents.touchUpInside)
        self.addTarget(self, action:#selector(touchDownHandler(sender:)), for: UIControlEvents.touchDown)
        self.isChecked = false
        
        self.tintColor = UIColor.black
    }
    
    @objc func touchUpInsideHandler(sender: UIButton) {
        if sender == self {
            isChecked = !isChecked
        }
    }
    
    @objc func touchDownHandler(sender: UIButton) {
        if sender == self {
            // This prevents the image from fading on Button Touch Down
            if let imageView = sender.imageView {
                imageView.alpha = 1.0
            }
        }
    }
}
