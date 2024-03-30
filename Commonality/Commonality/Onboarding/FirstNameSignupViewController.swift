//
//  FirstNameSignupViewController.swift
//  Commonality
//
//  Created by Thabo David Klass on 31/01/2017.
//  Copyright © 2017 Spreebie, Inc. All rights reserved.
//

/// The first name signup page class of the Commonality application
class FirstNameSignupViewController: UIViewController, UIViewControllerTransitioningDelegate, UITextFieldDelegate {
    /// This is the sign up button
    @IBOutlet weak var backButton: UIButton!
    
    /// This is the next button
    @IBOutlet weak var nextButton: UIButton!
    
    /// This is the sign up progress indicator
    @IBOutlet weak var signupProgressView: UIProgressView!
    
    /// The user first name text field
    @IBOutlet weak var firstNameUserTextField: UITextField!
    
    /// The third page image view
    @IBOutlet weak var thirdSignupPageImageView: UIImageView!
    
    /// The user's email
    var userEmail: String? = String()
    
    // The user's interests
    var interests = [String]()
    
    var counter:Int = 0 {
        didSet {
            let fractionalProgress = Float(counter) / 100.0
            let animated = counter != 0
            
            signupProgressView.setProgress(fractionalProgress, animated: animated)
        }
    }
    
    override func viewDidLoad() {
        /// Create a rounder border for the button
        let backButtonLayer: CALayer?  = backButton.layer
        backButtonLayer!.cornerRadius = 4
        backButtonLayer!.masksToBounds = true
        
        let nextButtonLayer: CALayer?  = nextButton.layer
        nextButtonLayer!.cornerRadius = 4
        nextButtonLayer!.masksToBounds = true
        
        var titleString = NSMutableAttributedString()
        let title = "first name"
        
        titleString = NSMutableAttributedString(string:title, attributes: [NSAttributedStringKey.font: UIFont(name: "Avenir", size: 14)!]) // Font
        titleString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor(red: 169.0/255.0, green: 43.0/255.0, blue: 41.0/255.0, alpha: 0.7), range:NSRange(location:0,length:title.characters.count))    // Color
        firstNameUserTextField.attributedPlaceholder = titleString
        
        /// So the textfield delegate functions work
        firstNameUserTextField.delegate = self
        
        /// Set the progress of the signup progress indicator
        signupProgressView.setProgress(0.2, animated: false)
        startCount()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        thirdSignupPageImageView = nil
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "moveNextToFourthFromThird") {
            weak var lnsvc = segue.destination as? LastNameSignupViewController
            
            /// Pass the text enter info to the next view controller
            lnsvc?.userEmail = userEmail
            
            let userFirstName = firstNameUserTextField.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            lnsvc?.userFirstName = userFirstName
            lnsvc?.interests = interests
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "moveNextToFourthFromThird" {
            
            if firstNameUserTextField.text!.isEmpty {
                // Empty fields.
                displayMyAlertMessage("Missing field", userMessage: "The first name field is required.")
                return false
            }
        }
        return true
    }
    
    /**
     Displays and alert.
     
     - Parameters:
     - title: The title text
     - userMessage: The message text
     
     - Returns: void.
     */
    func displayMyAlertMessage(_ title: String, userMessage: String) {
        let myAlert = UIAlertController(title: title, message: userMessage, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
        myAlert.addAction(okAction)
        
        self.present(myAlert, animated: true, completion: nil)
    }
    
    /// Textfield delegate function
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // Counts the progress of the onboarding process
    func startCount() {
        self.counter = 25
        for _ in 25..<50 {
            DispatchQueue.global().async {
                
                sleep(1)
                DispatchQueue.main.async(execute: {
                    self.counter += 1
                    return
                })
            }
        }
    }
}
