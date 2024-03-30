//
//  EmailSignupViewController.swift
//  Commonality
//
//  Created by Thabo David Klass on 31/01/2017.
//  Copyright © 2017 Spreebie, Inc. All rights reserved.
//

import FBSDKCoreKit
import FBSDKLoginKit
import FirebaseFirestore

/// The email signup page class of the Commonality application
class EmailSignupViewController: UIViewController, UIViewControllerTransitioningDelegate, UITextFieldDelegate, FBSDKLoginButtonDelegate, TagListViewDelegate {
    /// This is the back button
    @IBOutlet weak var backButton: UIButton!
    
    /// This is the next button
    @IBOutlet weak var nextButton: UIButton!
    
    /// This is the sign up progress indicator
    @IBOutlet weak var signupProgressView: UIProgressView!
    
    /// The user email text field
    @IBOutlet weak var userEmailTextField: UITextField!
    
    /// The second page image view
    @IBOutlet weak var secondSignupPageImageView: UIImageView!
    
    /// The Facebook login button
    @IBOutlet weak var loginFBSDKLoginButton: FBSDKLoginButton!
    
    /// The tag list
    @IBOutlet weak var interestTagList: TagListView!
    
    var counter:Int = 0 {
        didSet {
            let fractionalProgress = Float(counter) / 100.0
            let animated = counter != 0
            
            signupProgressView.setProgress(fractionalProgress, animated: animated)
        }
    }
    
    // The user's FB email
    var userFBEmail: String? = nil
    
    /// The user's FB first name
    var userFBFirstName: String? = nil
    
    /// The user's FB last name
    var userFBLastName: String? = nil
    
    /// The facebook profile picture
    var facebookProfilePictureImage: UIImage? = nil
    
    // The user's interests
    var interests = [String]()
    
    override func viewDidLoad() {
        /// Create a rounder border for the button
        let backButtonLayer: CALayer?  = backButton.layer
        backButtonLayer!.cornerRadius = 4
        backButtonLayer!.masksToBounds = true
        
        let nextButtonLayer: CALayer?  = nextButton.layer
        nextButtonLayer!.cornerRadius = 4
        nextButtonLayer!.masksToBounds = true
        
        var titleString = NSMutableAttributedString()
        let title = "email address"
        
        titleString = NSMutableAttributedString(string:title, attributes: [NSAttributedStringKey.font: UIFont(name: "Avenir", size: 14)!]) // Font
        titleString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor(red: 169.0/255.0, green: 43.0/255.0, blue: 41.0/255.0, alpha: 0.7), range:NSRange(location:0,length:title.characters.count))    // Color
        userEmailTextField.attributedPlaceholder = titleString
        
        /// So the textfield delegate functions work
        userEmailTextField.delegate = self
        
        /// Set the progress of the signup progress indicator
        signupProgressView.setProgress(0, animated: false)
        startCount()
        
        /// Make this class the delegate of the FB button
        loginFBSDKLoginButton.delegate = self
        
        /// Configure the read permissions
        loginFBSDKLoginButton.readPermissions = ["public_profile", "email"]
        
        /// If somehow, through a bizzare event, the user is already
        /// connected via facebook, move the process forward
        if (FBSDKAccessToken.current() == nil) {
            print("Not logged in...")
        } else {
            print("Logged in..")
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        
        view.addGestureRecognizer(tap)
        
        /// Log an open event on FB Analytics
        FBSDKAppEvents.logEvent("secondSignupOpened")
        
        interestTagList.delegate = self
        interestTagList.textFont = UIFont.systemFont(ofSize: 16)
        interestTagList.shadowRadius = 2
        interestTagList.shadowOpacity = 0.4
        interestTagList.shadowColor = UIColor.black
        interestTagList.shadowOffset = CGSize(width: 1, height: 1)

        interestTagList.addTag("Art & Fashion")
        interestTagList.addTag("Cars")
        interestTagList.addTag("Gaming")
        interestTagList.addTag("Movies & TV")
        interestTagList.addTag("Music")
        interestTagList.addTag("Politics")
        interestTagList.addTag("Science & Tech")
        interestTagList.addTag("Sports")
        interestTagList.addTag("Travel")
        interestTagList.alignment = .center
    }
    
    /**
     This get the FB data after user taps the FB button
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func getFBData() {
        /// The parameters of that we want from Facebook
        let parameters = ["fields": "email, first_name, last_name, picture.type(large)"]
        
        /// Create a graph request to get the user details
        let userDetails = FBSDKGraphRequest(graphPath: "me", parameters: parameters)
        
        /// Start the request
        userDetails?.start(completionHandler: { (connection, result, error) -> Void in
            if error != nil {
                print(error)
                return
            }
            
            /// Convert the result to a dictionary
            let data = result as! [String:AnyObject]
            
            /// Get the user email
            if let email = data["email"] as? String {
                print(email)
                self.userFBEmail = email
            }
            
            /// Get the user first name
            if let firstName = data["first_name"] as? String {
                print(firstName)
                self.userFBFirstName = firstName
            }
            
            /// Get the user last name
            if let lastName = data["last_name"] as? String {
                print(lastName)
                self.userFBLastName = lastName
            }
            
            /// Get the profile picture URL - we do not use this at the
            /// present moment
            if let picture = data["picture"] as? NSDictionary, let data = picture["data"] as? NSDictionary, let url = data["url"] as? String {
                print(url)
            }
            
            /// Perform a seque that skips the unnecessary steps
            self.performSegue(withIdentifier: "goToPasswordsFromFBLogin", sender: nil)
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        secondSignupPageImageView = nil
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /// Textfield delegate function
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "moveNextToThirdFromSecond") {
            weak var fnsvc = segue.destination as? FirstNameSignupViewController
            
            /// Pass the text enter info to the next view controller
            let userEmail = userEmailTextField.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            fnsvc?.userEmail = userEmail
            fnsvc?.interests = interests
        }
        
        if (segue.identifier == "goToLoginFromProducts") {
            //weak var lvc = segue.destination as? LoginViewController
            //lvc!.dialogParent = self.navigationController!.tabBarController!
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "moveNextToThirdFromSecond" {
            
            if userEmailTextField.text!.isEmpty {
                // Empty fields.
                displayMyAlertMessage("Missing field", userMessage: "The email field is required.")
                return false
            }
            
            if !isValidEmail(testStr: userEmailTextField.text!) {
                // Empty fields.
                displayMyAlertMessage("Invalid email", userMessage: "The email you entered is not valid. Please try again.")
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
    
    /**
     Displays and alert.
     
     - Parameters:
     - testStr: The email address to be validated
     
     - Returns: Boolean.
     */
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "^(?:(?:(?:(?: )*(?:(?:(?:\\t| )*\\r\\n)?(?:\\t| )+))+(?: )*)|(?: )+)?(?:(?:(?:[-A-Za-z0-9!#$%&’*+/=?^_'{|}~]+(?:\\.[-A-Za-z0-9!#$%&’*+/=?^_'{|}~]+)*)|(?:\"(?:(?:(?:(?: )*(?:(?:[!#-Z^-~]|\\[|\\])|(?:\\\\(?:\\t|[ -~]))))+(?: )*)|(?: )+)\"))(?:@)(?:(?:(?:[A-Za-z0-9](?:[-A-Za-z0-9]{0,61}[A-Za-z0-9])?)(?:\\.[A-Za-z0-9](?:[-A-Za-z0-9]{0,61}[A-Za-z0-9])?)*)|(?:\\[(?:(?:(?:(?:(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))\\.){3}(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))))|(?:(?:(?: )*[!-Z^-~])*(?: )*)|(?:[Vv][0-9A-Fa-f]+\\.[-A-Za-z0-9._~!$&'()*+,;=:]+))\\])))(?:(?:(?:(?: )*(?:(?:(?:\\t| )*\\r\\n)?(?:\\t| )+))+(?: )*)|(?: )+)?$"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        let result = emailTest.evaluate(with: testStr)
        return result
    }
    
    // Counts the progress of the onboarding process
    func startCount() {
        self.counter = 0
        for _ in 0..<25 {
            DispatchQueue.global().async {
                
                sleep(1)
                DispatchQueue.main.async(execute: {
                    self.counter += 1
                    return
                })
            }
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func loginButtonWillLogin(_ loginButton: FBSDKLoginButton!) -> Bool {
        return true
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("Did log out of facebook")
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if error != nil {
            print(error)
            return
        }
        
        self.loginFBSDKLoginButton.isEnabled = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        signIn()
    }
    
    /**
     Sign in with Facebook
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func signIn() {
        FBSDKGraphRequest(graphPath: "/me", parameters: ["fields": "id, name, email"]).start { (connection, result, err) in
            
            if err != nil {
                print("Failed to start graph request:", err ?? "")
                self.loginFBSDKLoginButton.isEnabled = true
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                return
            } else {
                guard let result = result as? NSDictionary,
                    let email = result["email"] as? String,
                    let name = result["name"] as? String else {
                        return
                }
                
                let accessToken = FBSDKAccessToken.current()
                guard let accessTokenString = accessToken?.tokenString else { return }
                
                let credentials = FacebookAuthProvider.credential(withAccessToken: accessTokenString)
                Auth.auth().signIn(with: credentials, completion: { (user, error) in
                    if error != nil {
                        print("Something went wrong with our FB user: ", error ?? "")
                        self.loginFBSDKLoginButton.isEnabled = true
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        
                        return
                    } else {
                        self.loginFBSDKLoginButton.isEnabled = true
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        
                        // Set the Commonality user ID
                        KeychainWrapper.standard.set((user?.user.uid)!, forKey: ApplicationConstants.commonalityUserIDKey)
                        
                        // Set recently logged in to true. This will be used to refresh data
                        // on the HomeViewController
                        KeychainWrapper.standard.set(ApplicationConstants.commonalitySmallYesValue, forKey: ApplicationConstants.commonalityUserJustLoggedInValue)
                        
                        self.setUserDataFacebook(fullName: name, email: email, uid: (user?.user.uid)!)
                    }
                    
                    print("Successfully logged in with our user: ", user ?? "")
                })
            }
            print(result ?? "")
        }
    }
    
    /**
     This saves the new user to the database.
     
     - Parameters:
     - user: The user name
     - uid: The unique ID
     
     - Returns: void.
     */
    func setUserDataFacebook(fullName: String, email: String, uid: String) {
        /// Create the unix time stamp
        let currentDate = Date()
        let timeStamp = Int(currentDate.timeIntervalSince1970)
        
        let userData: Dictionary<String, AnyObject> = [
            "firstName": ApplicationConstants.dbEmptyValue as AnyObject,
            "lastName": ApplicationConstants.dbEmptyValue as AnyObject,
            "fullName": fullName as AnyObject,
            "email": email as AnyObject,
            "deviceToken": ApplicationConstants.dbEmptyValue as AnyObject,
            "deviceArn": ApplicationConstants.dbEmptyValue as AnyObject,
            "profilePictureFileName": ApplicationConstants.dbEmptyValue as AnyObject,
            "measuringSystem": "imperial" as AnyObject,
            "creationAt": timeStamp  as AnyObject,
            "updatedAt": timeStamp  as AnyObject,
            "status": "Hi there! I'm using Commonality!" as AnyObject,
            "interests": interests as AnyObject
        ]
        
        let dBase = Firestore.firestore()
        
        dBase.collection("users").document(uid).setData(userData) { (error) in
            if let error = error {
                print("\(error.localizedDescription)")
            } else {
                self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func termsButtonTapped(_ sender: AnyObject) {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(URL(string: ApplicationConstants.commonalityTermsURL)!, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(URL(string: ApplicationConstants.commonalityTermsURL)!)
        }
    }
    
    // MARK: TagListViewDelegate
    func tagPressed(_ title: String, tagView: TagView, sender: TagListView) {
        tagView.isSelected = !tagView.isSelected
        
        if interests.contains(title) {
            var count = 0
            for interest in interests {
                if interest == title {
                    interests.remove(at: count)
                    break
                }
                
                count += 1
            }
        } else {
            interests.append(title)
        }
    }
    
    func tagRemoveButtonPressed(_ title: String, tagView: TagView, sender: TagListView) {
        sender.removeTagView(tagView)
    }
}
