//
//  LoginViewController.swift
//  Commonality
//
//  Created by Thabo David Klass on 25/01/2016.
//  Copyright © 2016 Spreebie, Inc. All rights reserved.
//
import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import FirebaseFirestore

/// The Login page class
class LoginViewController: UIViewController, UITextFieldDelegate, FBSDKLoginButtonDelegate {
    /// The parent tab bar controlller
    var dialogParent = UITabBarController()
    
    /// If the user data from facebook has been populated
    var userDataPopulated = false
    
    /// Test variable for facebook
    var usernameFBTest: String? = String()
    
    /// Another test variable for facebook
    var emailFBTest: String? = String()
    
    /// The facebook user's objectID
    var objectID: String? = String()
    
    /// The user first name
    var userFirstName: String? = String()
    
    /// The user last name
    var userLastName: String? = String()
    
    /// The back button
    @IBOutlet weak var backButton: UIButton!
    
    /// The user email text field
    @IBOutlet weak var userEmailTextField: UITextField!
    
    /// The user password text field
    @IBOutlet weak var userPasswordTextField: UITextField!
    
    /// The user login button
    @IBOutlet weak var userLoginButton: UIButton!
    
    /// Login page image view
    @IBOutlet weak var loginPageImageView: UIImageView!
    
    /// Facebook login button
    @IBOutlet weak var loginFBSDKLoginButton: FBSDKLoginButton!
    
    /// The user fb_auth name
    var fbAuth: String? = String()
    
    /// The user email name
    var fbEmail: String? = String()
    
    override func viewDidLoad() {
        /// Create rounded corners for the user login button
        let backButtonLayer: CALayer?  = backButton.layer
        backButtonLayer!.cornerRadius = 4
        backButtonLayer!.masksToBounds = true
        
        let userLoginButtonLayer: CALayer?  = userLoginButton.layer
        userLoginButtonLayer!.cornerRadius = 4
        userLoginButtonLayer!.masksToBounds = true
        
        var titleString = NSMutableAttributedString()
        let title = "email address"
        
        titleString = NSMutableAttributedString(string:title, attributes: [NSAttributedStringKey.font: UIFont(name: "Avenir", size: 14)!]) // Font
        titleString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor(red: 169.0/255.0, green: 43.0/255.0, blue: 41.0/255.0, alpha: 0.7), range:NSRange(location:0,length:title.characters.count))    // Color
        userEmailTextField.attributedPlaceholder = titleString
        
        var titleString2 = NSMutableAttributedString()
        let title2 = "password"
        
        titleString2 = NSMutableAttributedString(string:title2, attributes: [NSAttributedStringKey.font: UIFont(name: "Avenir", size: 14)!]) // Font
        titleString2.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor(red: 169.0/255.0, green: 43.0/255.0, blue: 41.0/255.0, alpha: 0.7), range:NSRange(location:0,length:title2.characters.count))    // Color
        userPasswordTextField.attributedPlaceholder = titleString2
        
        /// Make this class the delegate for the Facebook button
        loginFBSDKLoginButton.delegate = self
        
        /// Configure read permissions
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
        
        FBSDKAppEvents.logEvent("loginOpened")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        loginPageImageView = nil
    }
    
    /**
     This reacts to the login button tapped action
     
     - Parameters:
     - sender: The login button
     
     - Returns: void.
     */
    @IBAction func loginButtonTapped(_ sender: AnyObject) {
        let userEmail = userEmailTextField.text
        let userPassword = userPasswordTextField.text
        
        if userEmail!.isEmpty || userPassword!.isEmpty {
            // Empty fields.
            displayMyAlertMessage("Missing field(s)", userMessage: "The email and password fields are required.")
        } else {
            self.userLoginButton.isEnabled = false
            self.loginFBSDKLoginButton.isEnabled = false
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            /// Login on Firebase as well
            Auth.auth().signIn(withEmail: userEmail!, password: userPassword!) { (fireUser, error) in
                if error == nil {
                    KeychainWrapper.standard.set((fireUser?.user.uid)!, forKey: ApplicationConstants.commonalityUserIDKey)
                    KeychainWrapper.standard.set(ApplicationConstants.commonalitySmallYesValue, forKey: ApplicationConstants.commonalityUserJustLoggedInValue)
                    
                    self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
                } else {
                    self.userLoginButton.isEnabled = true
                    self.loginFBSDKLoginButton.isEnabled = true
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    
                    self.displayMyAlertMessage("Error", userMessage: "The login data you entered is incorrect. Please try again.")
                }
            }
        }
    }
    
    /**
     This resets your password
     
     - Parameters:
     - sender: The password reset button
     
     - Returns: void.
     */
    @IBAction func resetButtonTapped(_ sender: AnyObject) {
        let userEmail = userEmailTextField.text
        
        if userEmail!.isEmpty {
            // Empty fields.
            displayMyAlertMessage("Fill email field", userMessage: "Please enter your email in the field to reset your pasword.")
        } else {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            Auth.auth().sendPasswordReset(withEmail: userEmail!) { error in
                if error != nil {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    let errorMessage = error!.localizedDescription
                    self.displayMyAlertMessage("Reset Error", userMessage: errorMessage)
                } else {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self.displayMyAlertMessage("Reset email", userMessage: "A reset message has been sent to your email. Please make sure your reset password is 6 characters or longer.")
                }
            }
        }
    }
    
    /**
     This sets the user as logged in.
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func setAsLoggedIn() {
        UserDefaults.standard.set(true, forKey: "isUserLoggedInSpreebie")
        UserDefaults.standard.synchronize()
        self.dismiss(animated: true, completion: nil)
    }
    
    /**
     This disables all the tabs that requier login.
     
     - Parameters:
     - patriarch: The parent tab bar controller
     
     - Returns: void.
     */
    func disableTabsThatReguireLogin(_ patriarch: UITabBarController) {
        let arrayOfTabBarItems = patriarch.tabBar.items as [UITabBarItem]?
        if arrayOfTabBarItems != nil {
            let tabBarItem2 = arrayOfTabBarItems![2]
            tabBarItem2.isEnabled = false
            let tabBarItem3 = arrayOfTabBarItems![3]
            tabBarItem3.isEnabled = false
            let tabBarItem4 = arrayOfTabBarItems![4]
            tabBarItem4.isEnabled = false
        }
    }
    
    /**
     This enables all the tabs after successful login.
     
     - Parameters:
     - patriarch: The parent tab bar controller
     
     - Returns: void.
     */
    func enableTabsThatReguireLogin(_ patriarch: UITabBarController) {
        let arrayOfTabBarItems = patriarch.tabBar.items as [UITabBarItem]?
        if arrayOfTabBarItems != nil {
            let tabBarItem2 = arrayOfTabBarItems![2]
            tabBarItem2.isEnabled = true
            let tabBarItem3 = arrayOfTabBarItems![3]
            tabBarItem3.isEnabled = true
            let tabBarItem4 = arrayOfTabBarItems![4]
            tabBarItem4.isEnabled = true
        }
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
        userEmailTextField.resignFirstResponder()
        userPasswordTextField.resignFirstResponder()
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /*if (segue.identifier == "goToRegisterFromLogin") {
            weak var rvc = segue.destination as? RegisterViewController
            rvc!.dialogParent = self.dialogParent
        }*/
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /**
     This saves the new user to Commonality Firebase dBase.
     
     - Parameters:
     - user: The user name
     - uid: The unique ID
     
     - Returns: void.
     */
    func setFireUserName(userName: String, uid: String) {
        let userData = [
            "username": userName,
            "userImg": ApplicationConstants.dbEmptyValue
        ]
        
        let user = Database.database().reference().child("users").child(uid)
        
        user.setValue(userData)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // Facebook login delegate method 1
    func loginButtonWillLogin(_ loginButton: FBSDKLoginButton!) -> Bool {
        return true
    }
    
    // Facebook login delegate method 2
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("Did log out of facebook")
    }
    
    // Facebook login delegate method 3
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if error != nil {
            print(error)
            self.userLoginButton.isEnabled = true
            self.loginFBSDKLoginButton.isEnabled = true
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            return
        }
        
        self.userLoginButton.isEnabled = false
        self.loginFBSDKLoginButton.isEnabled = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        signIn()
    }
    
    
    // Implementation of the Facebook login API
    func signIn() {
        FBSDKGraphRequest(graphPath: "/me", parameters: ["fields": "id, name, email"]).start { (connection, result, err) in
            
            if err != nil {
                print("Failed to start graph request:", err ?? "")
                self.userLoginButton.isEnabled = true
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
                        self.userLoginButton.isEnabled = true
                        self.loginFBSDKLoginButton.isEnabled = true
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        
                        return
                    } else {
                        // Set the Commonality user ID
                        KeychainWrapper.standard.set((user?.user.uid)!, forKey: ApplicationConstants.commonalityUserIDKey)
                        
                        // Set recently logged in to true. This will be used to refresh data
                        // on the HomeViewController
                        KeychainWrapper.standard.set(ApplicationConstants.commonalitySmallYesValue, forKey: ApplicationConstants.commonalityUserJustLoggedInValue)
                        
                        let dBase = Firestore.firestore()
                        let userRef = dBase.collection("users").document((user?.user.uid)!)
                        
                        userRef.getDocument { (document, error) in
                            if let document = document, document.exists {
                                print("User already exists")
                            } else {
                                self.setUserDataFacebook(fullName: name, email: email, uid: (user?.user.uid)!)
                            }
                        }
                        
                        self.userLoginButton.isEnabled = true
                        self.loginFBSDKLoginButton.isEnabled = true
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        
                        self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
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
            "status": "Hi there! I'm using Commonality!" as AnyObject
        ]
        
        let dBase = Firestore.firestore()
        
        dBase.collection("users").document(uid).setData(userData) { (error) in
            if let error = error {
                print("\(error.localizedDescription)")
            } else {
                print("Document was successfully created and written.")
            }
        }
    }
}
