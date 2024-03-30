//
//  RadioButton.swift
//  Commonality
//
//  Created by Thabo David Klass on 17/4/18.
//  Copyright © 2018 Spreebie, Inc. All rights reserved.
//

import UIKit

// This an implementation of a radio button
class RadioButton: UIButton {
    var alternateButton:Array<RadioButton>?
    let selectedImage: UIImage = #imageLiteral(resourceName: "radio-selected")
    let unselectedImage: UIImage = #imageLiteral(resourceName: "radio-unselected")
    
    override func awakeFromNib() {
        self.layer.backgroundColor = UIColor.white.cgColor
        
        self.tintColor = UIColor.black
    }
    
    func unselectAlternateButtons(){
        if alternateButton != nil {
            self.isSelected = true
            
            for aButton:RadioButton in alternateButton! {
                aButton.isSelected = false
            }
        }else{
            toggleButton()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        unselectAlternateButtons()
        super.touchesBegan(touches, with: event)
    }
    
    func toggleButton(){
        self.isSelected = !isSelected
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                self.setImage(selectedImage, for: UIControlState.normal)
            } else {
                self.setImage(unselectedImage, for: UIControlState.normal)
            }
        }
    }

}
