//
//  StandardPopupViewController.swift
//  Spreebie
//
//  Created by Thabo David Klass on 13/04/2017.
//  Copyright © 2017 Spreebie, Inc. All rights reserved.
//

import UIKit

/// The fourth signup page class of the Spreebie application
class StandardPopupViewController: UIViewController {
    /// The view container
    @IBOutlet weak var popupView: UIView!
    
    /// The view constraints
    @IBOutlet weak var centerPopupConstraint: NSLayoutConstraint!
    
    /// The informative text label
    @IBOutlet weak var informativeTextLabel: UILabel!
    
    /// The infomative text
    var informativeText = String()
    
    /// The index of the parent view controller
    var selectedTabIndex = 0
    
    /// The current user
    var currentUser: String? = KeychainWrapper.standard.string(forKey: ApplicationConstants.commonalityUserIDKey)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        popupView.layer.cornerRadius = 10
        popupView.layer.masksToBounds = true
        popupView.layer.borderWidth = 2.0
        popupView.layer.borderColor = UIColor.white.cgColor
        
        /// Assign the informative text to the label
        informativeTextLabel.text = informativeText
    }
    
    override func viewDidAppear(_ animated: Bool) {
        centerPopupConstraint.constant = 0
        
        /// When the view appear, disable all other tabs beside
        /// the currently selected tab
        disableTabsButCurrentIndex(index: selectedTabIndex)
        
        /// Animate the popup
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        centerPopupConstraint.constant = -400
        
        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutIfNeeded()
        })
        
        if currentUser != nil {
            enableLoggedInTabs()
        } else {
            enableLoggedOutTabs()
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    /**
     This enables all the tabs the logged in tabs.
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func enableLoggedInTabs() {
        let tabBarController = UIApplication.shared.keyWindow?.rootViewController as! UITabBarController
        let arrayOfTabBarItems = tabBarController.tabBar.items as [UITabBarItem]?
        if arrayOfTabBarItems != nil {
            let tabBarItem0 = arrayOfTabBarItems![0]
            tabBarItem0.isEnabled = true
            let tabBarItem1 = arrayOfTabBarItems![1]
            tabBarItem1.isEnabled = true
            let tabBarItem2 = arrayOfTabBarItems![2]
            tabBarItem2.isEnabled = true
            let tabBarItem3 = arrayOfTabBarItems![3]
            tabBarItem3.isEnabled = true
        }
    }
    
    /**
     This enables all the logged out tabs.
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func enableLoggedOutTabs() {
        let tabBarController = UIApplication.shared.keyWindow?.rootViewController as! UITabBarController
        let arrayOfTabBarItems = tabBarController.tabBar.items as [UITabBarItem]?
        if arrayOfTabBarItems != nil {
            let tabBarItem0 = arrayOfTabBarItems![0]
            tabBarItem0.isEnabled = true
        }
    }
    
    /**
     This disables all the tabs besides the selected index.
     
     - Parameters:
     - index: The selected index
     
     - Returns: void.
     */
    func disableTabsButCurrentIndex(index: Int) {
        let tabBarController = UIApplication.shared.keyWindow?.rootViewController as! UITabBarController
        let arrayOfTabBarItems = tabBarController.tabBar.items as [UITabBarItem]?
        var currentIndex = 0
        
        if arrayOfTabBarItems != nil {
            for tabBarItem in arrayOfTabBarItems! {
                if currentIndex != index {
                   tabBarItem.isEnabled = false
                }
                
                currentIndex += 1
            }
        }
    }
}
