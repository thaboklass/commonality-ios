//
//  FirstSignupPageViewController.swift
//  Commonality
//
//  Created by Thabo David Klass on 30/01/2017.
//  Copyright © 2017 Spreebie, Inc. All rights reserved.
//

/// The first signup page class of the Commonality application
class WelcomeViewController: UIViewController, UIViewControllerTransitioningDelegate {
    /// This is the "Home "button that closes the view controller
    @IBOutlet weak var closeButton: UIButton!
    
    /// This is the sign up button
    @IBOutlet weak var signupButton: UIButton!
    
    /// This is the login button
    @IBOutlet weak var loginButton: UIButton!
    
    /// This is the sign up progress indicator
    @IBOutlet weak var signupProgressView: UIProgressView!
    
    /// This is the onboarder logo
    @IBOutlet weak var onboarderLgoImageView: UIImageView!
    
    /// This the first page image
    @IBOutlet weak var firstSignupPageImageView: UIImageView!
    
    
    /// The parent tab bar controller
    public var dialogParent = UITabBarController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /// Restore dimming feature
        UIApplication.shared.isIdleTimerDisabled = false
        
        /// Create a rounder border for the button
        let closeButtonLayer: CALayer?  = closeButton.layer
        closeButtonLayer!.cornerRadius = 4
        closeButtonLayer!.masksToBounds = true
        
        /// Create a rounder border for the button
        let signupButtonLayer: CALayer?  = signupButton.layer
        signupButtonLayer!.cornerRadius = 4
        signupButtonLayer!.masksToBounds = true
        
        /// Create a rounder border for the button
        let loginButtonLayer: CALayer?  = loginButton.layer
        loginButtonLayer!.cornerRadius = 4
        loginButtonLayer!.masksToBounds = true
        
        /// Set the progress of the signup progress indicator
        signupProgressView.setProgress(0, animated: false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        onboarderLgoImageView = nil
        firstSignupPageImageView = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
    
    // The home button dismisses the view controller
    @IBAction func homeButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
