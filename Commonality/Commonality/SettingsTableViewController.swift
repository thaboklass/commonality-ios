//
//  SpreebieSettingsTableViewController.swift
//  Spreebie
//
//  Created by Thabo David Klass on 03/01/2016.
//  Copyright © 2016 Spreebie, Inc. All rights reserved.
//

import UIKit
import MessageUI
import CoreLocation
import FirebaseAuth
import FBSDKCoreKit
import FBSDKLoginKit
import FirebaseFirestore

/// This is the Settings table view class
class SettingsTableViewController: UITableViewController, UITextFieldDelegate, MFMailComposeViewControllerDelegate, CLLocationManagerDelegate {
    /// This is the full name text field
    @IBOutlet weak var fullNameTextField: UITextField!
    
    /// This is the profile picture imaage view
    @IBOutlet weak var profilePictureImageView: UIImageView!
    
    /// This is the email text field
    @IBOutlet weak var emailTextField: UITextField!
    
    /// This is the save changes bar button item
    @IBOutlet weak var saveChangesBarButtonItem: UIBarButtonItem!
    
    /// This changes the profile pic when clicked
    @IBOutlet weak var changeProfilePicButton: UIButton!
    
    /// The logout button
    @IBOutlet weak var logoutButton: UIButton!
    
    /// The clear image history button
    @IBOutlet weak var clearVideoHistoryButton: UIButton!
    
    /// This is the email feedback button
    @IBOutlet weak var reachOutButton: UIButton!
    
    /// The contact us button
    @IBOutlet weak var contactUsViaWebPageButton: UIButton!
    
    /// This is the privacy policy button
    @IBOutlet weak var privacyPolicyButton: UIButton!
    
    /// This is the privacy policy button
    @IBOutlet weak var termsButton: UIButton!
    
    /// The popup button
    @IBOutlet weak var enablePopupButton: UIButton!
    
    /// The popup switch
    @IBOutlet weak var popupSwitch: UISwitch!
    
    /// The borderView
    @IBOutlet weak var borderView: UIView!
    
    /// The user first name string
    var userFirstName: String? = String()
    
    /// The user profile picture name
    var profilePictureFileName: String? = String()
    
    /// the user email
    var userEmail: String? = String()
    
    /// This holds where the email exists
    var checkIfEmailExistsFirstName: String? = String()
    
    var currentEmail: String!
    
    /// The application measuring system
    var measuringSystem = "imperial"
    
    /// Whether the current device token and ARN have been saved.
    var currentDeviceTokenAndArnSaved = false
    
    /// This records whether a segue happened
    var didSegueToProfilePictureUploadPage = false
    
    /// The current logged in user
    var currentUser: String? = KeychainWrapper.standard.string(forKey: ApplicationConstants.commonalityUserIDKey)
    
    /// The third loop count
    var count3: Int = 0
    
    /// The unseen message count
    var unseenMessageCount: Int = 0
    
    /// The fourth loop count
    var count4: Int = 0
    
    /// The unseen message count
    var unseenAlertCount: Int = 0
    
    /// Has the popup been shown
    var popupShown = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        self.tableView.allowsSelection = false
        /// Sets the navigation graphic primitives to a light blue color
        let darkGray = UIColor(red: 61.0/255.0, green: 61.0/255.0, blue: 61.0/255.0, alpha: 1.0)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: darkGray]
        
        /// This creates rounded corners for the image view
        let greenish = UIColor(red: 45.0/255.0, green: 182.0/255.0, blue: 174.0/255.0, alpha: 1.0)

        let imageLayer: CALayer?  = self.profilePictureImageView.layer
        imageLayer!.borderWidth = 2.0
        imageLayer!.borderColor = UIColor.white.cgColor
        
        imageLayer!.cornerRadius = profilePictureImageView.frame.height / 2
        imageLayer!.masksToBounds = true
        
        let borderLayer: CALayer?  = self.borderView.layer
        borderLayer!.borderWidth = 2.5
        borderLayer!.borderColor = greenish.cgColor
        
        borderLayer!.cornerRadius = borderView.frame.height / 2
        borderLayer!.masksToBounds = true
        
        /// Set the switch color
        popupSwitch.onTintColor = greenish
        popupSwitch.tintColor = greenish
        
        /// Set the delegate of these text fields
        fullNameTextField.delegate = self
        emailTextField.delegate = self
        
        /// Disable in interface until the data is loaded
        disableInterface()
        
        /// If the current user is not nil...
        if currentUser != nil {
            setUserData()
            saveCurrentDeviceTokenAndArn()
        }
        
        let showPopups = KeychainWrapper.standard.string(forKey: "commonalityShowPopups")
        
        if showPopups != nil {
            if showPopups == ApplicationConstants.commonalitySmallNoValue {
                popupSwitch.isOn = false
            } else {
                popupSwitch.isOn = true
            }
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /// Keep Commonality on
        UIApplication.shared.isIdleTimerDisabled = true
        
        /// Set the home page segue thing to false
        ApplicationConstants.hasASeguedHappenedInTheHomePage = false
        
        // In case the page has been opened before
        currentUser = KeychainWrapper.standard.string(forKey: ApplicationConstants.commonalityUserIDKey)
        
        /// If the current user is not nil...
        if currentUser != nil {
            setUserData()
            
            // Count the unread messages
            countUnreadMessages()
            
            // Count the unread alerts
            countUnreadNotifications()
        }
    }
    
    /// Go back
    @IBAction func doneBarButtonTapped(_ sender: Any) {
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
        }
    }
    
    /// Logout from Commonality
    @IBAction func logoutButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Log out: Are you sure?", message: "Are you sure you want to continue logging out from Commonality?", preferredStyle: UIAlertControllerStyle.alert)
        
        // add the actions (buttons)
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { (alert) -> Void in            
            /// Sign out of Facebook
            let loginManager = FBSDKLoginManager()
            loginManager.logOut()
            
            /// Sign out of Firebase
            let firebaseAuth = Auth.auth()
            do {
                try firebaseAuth.signOut()
                print("Signed out of Firebase")
            } catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
            }
            
            KeychainWrapper.standard.removeObject(forKey: ApplicationConstants.commonalityUserIDKey)
            
            KeychainWrapper.standard.set(ApplicationConstants.commonalitySmallYesValue, forKey: ApplicationConstants.commonalityUserJustLoggedOutValue)
            
            let parentTabBarController = self.tabBarController
            parentTabBarController?.selectedIndex = 0;
        }))
        alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: nil))
        
        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    /// Sets the user data into the table
    func setUserData() {
        /// Check for nil
        if currentUser != nil {
            let dBase = Firestore.firestore()
            let userRef = dBase.collection("users").document(currentUser!)
            
            userRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    if let userDict = document.data() {
                        /// Check for nil again
                        if let fullName = userDict["fullName"] as? String, let email = userDict["email"] as? String, let profilePictureFileName = userDict["profilePictureFileName"] as? String {
                            
                            /// Set the text data
                            self.fullNameTextField.text = fullName
                            self.emailTextField.text = email
                            self.currentEmail = email
                            
                            /// Set the profile picture data
                            if profilePictureFileName != ApplicationConstants.dbEmptyValue {
                                self.profilePictureFileName = profilePictureFileName
                                self.setProfilePicture()
                            } else {
                                if !self.popupShown {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                                        self.performSegue(withIdentifier: "OpenPopupFromSettings", sender: nil)
                                    })
                                    
                                    self.popupShown = true
                                }
                            }
                            
                            /// Enable the interface
                            self.enableInterface()
                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        }
                    }
                } else {
                    print("Error: \(error?.localizedDescription)")
                }
            }
        }
    }
    
    /// Disable user interface elements
    func disableInterface() {
        /// Disable all user interface elements before the data
        /// is loaded
        saveChangesBarButtonItem.isEnabled = false
        changeProfilePicButton.isEnabled = false
        clearVideoHistoryButton.isEnabled = false
        reachOutButton.isEnabled = false
        contactUsViaWebPageButton.isEnabled = false
        privacyPolicyButton.isEnabled = false
        termsButton.isEnabled = false
    }

    /// Enable user interface elements
    func enableInterface() {
        saveChangesBarButtonItem.isEnabled = true
        changeProfilePicButton.isEnabled = true
        clearVideoHistoryButton.isEnabled = true
        reachOutButton.isEnabled = true
        contactUsViaWebPageButton.isEnabled = true
        privacyPolicyButton.isEnabled = true
        termsButton.isEnabled = true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        textField.resignFirstResponder()
        return true
    }
    
    /// Set the profile picture
    func setProfilePicture() {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
        let documentDirectoryURL = URL(fileURLWithPath: documentDirectory)
        
        if let ppFileName = self.profilePictureFileName {
            //let fileName = "s-" + ppFileName
            let downloadSmallFileURL = documentDirectoryURL.appendingPathComponent(ppFileName)
            
            if FileManager.default.fileExists(atPath: downloadSmallFileURL.path) {
                self.insertProfilePic(self.profilePictureImageView, fileName: ppFileName, downloadFileURL: downloadSmallFileURL)
            } else {
                self.downloadProfilePic(self.profilePictureImageView, fileName: self.profilePictureFileName!, downloadFileURL: downloadSmallFileURL)
            }
        }
    }
    
    /**
     Downloads the profile pic from S3, stores it locally and inserts it into the cell.
     
     - Parameters:
     - imageView: The profile pic image view
     - fileName: The name of the file as it is store on S3
     - downloadULR: The local storage url
     
     - Returns: void.
     */
    func downloadProfilePic(_ imageView: UIImageView, fileName: String, downloadFileURL: URL) {
        /// When signing up, the user image is stored as "empty"
        if fileName != ApplicationConstants.dbEmptyValue {
            /// Get a reference to the image using the URL
            let ref = Storage.storage().reference(forURL: self.profilePictureFileName!)
            
            /// Get the image data
            ref.getData(maxSize: 10 * 1024 * 1024, completion: { (data, error) in
                if error != nil {
                    print(ApplicationConstants.profilePictureDownloadErrorMessage)
                } else {
                    if let imageData = data {
                        if let image = UIImage(data: imageData) {
                            imageView.alpha = 0
                            let imageLayer: CALayer?  = imageView.layer
                            imageLayer!.cornerRadius = imageView.frame.height / 2
                            //imageLayer!.cornerRadius = 6
                            imageLayer!.masksToBounds = true
                            
                            imageView.image = image
                            UIView.animate(withDuration: 0.5, animations: { () -> Void in
                                imageView.alpha = 1
                            })
                        }
                    }
                }
            })
        }
    }
    
    /**
     Retrives the profile pic locally and inserts it into the cell.
     
     - Parameters:
     - imageView: The profile pic image view
     - fileName: The name of the file as it is stored locally
     - downloadULR: The local storage url
     
     - Returns: void.
     */
    func insertProfilePic(_ imageView: UIImageView, fileName: String, downloadFileURL: URL) {
        DispatchQueue.main.async(execute: { () -> Void in
            if UIImage(named: downloadFileURL.path) != nil {
                imageView.alpha = 0
                let imageLayer: CALayer?  = imageView.layer
                imageLayer!.cornerRadius = imageView.frame.height / 2
                //imageLayer!.cornerRadius = 6
                imageLayer!.masksToBounds = true
                
                imageView.image = UIImage(named: downloadFileURL.path)!
                UIView.animate(withDuration: 0.5, animations: { () -> Void in
                    imageView.alpha = 1
                })
            }
        })
    }
    
    @IBAction func termsButtonTapped(_ sender: AnyObject) {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(URL(string: ApplicationConstants.commonalityTermsURL)!, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(URL(string: ApplicationConstants.commonalityTermsURL)!)
        }
    }
    
    @IBAction func privacyPolicyButtonTapped(_ sender: AnyObject) {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(URL(string: ApplicationConstants.commonalityPrivacyPolicyURL)!, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(URL(string: ApplicationConstants.commonalityPrivacyPolicyURL)!)
        }
    }
    
    @IBAction func contactUsViaWebPageTapped(_ sender: AnyObject) {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(URL(string: ApplicationConstants.commonalityContactUSURL)!, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(URL(string: ApplicationConstants.commonalityContactUSURL)!)
        }
    }
    
    /**
     Opens a feedback email view.
     
     - Parameters:
     - sender: The object that sent the action
     
     - Returns: void.
     */
    @IBAction func feedbackButtonTapped(_ sender: AnyObject) {
        let mailComposeViewController = self.configuredMailComposeViewController()
        
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendEmailErrorAlert()
        }
    }
    
    /**
     Constructs the Feedback email.
     
     - Parameters:
     - none
     
     - Returns: MFMailComposeViewController.
     */
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self
        
        mailComposeViewController.setToRecipients(["thabo@openbeacon.biz"])
        
        return mailComposeViewController
    }
    
    
    /**
     Shows an error alert when there's an email error.
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func showSendEmailErrorAlert() {
        displayMyAlertMessage("Could not send email", userMessage: "Your device could not send email. Please check your email setup and try again.")
    }
    
    /**
     An delegate method that listens for email events.
     
     - Parameters:
     - controller: MFMailComposeViewController
     - result: The email result
     - error: The error if any
     
     - Returns: void.
     */
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result.rawValue {
        case MFMailComposeResult.cancelled.rawValue:
            print("Cancelled mail.")
        case MFMailComposeResult.sent.rawValue:
            print("Mail sent.")
        default:
            break
        }
        
        self.dismiss(animated: true, completion: nil)
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
     Clears all the downloaded JPEG images from the phone
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func clearMediaFromPhone() {
        let fm = FileManager.default
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
        
        do {
            let items = try fm.contentsOfDirectory(atPath: documentDirectory)
            
            for item in items {
                if item.hasSuffix(".mov") || item.hasSuffix(".jpg") || item.hasSuffix(".png") {
                    let documentDirectoryURL = URL(fileURLWithPath: documentDirectory)
                    let fileURL = documentDirectoryURL.appendingPathComponent(item)
                    do {
                        try FileManager.default.removeItem(atPath: fileURL.path)
                    } catch {
                        print("Error: could not do it.")
                    }
                }
            }
        } catch {
            print("Error: could not do it.")
        }
        
        self.displayMyAlertMessage("Success!", userMessage: "Media data successfully cleared.")
    }
    
    @IBAction func clearMediaHistoryButtonTapped(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Clear Commonality media history?", message: "Whenever you view a piece of media of Commonality, it is cached on your device until the application is restarted.  Would you like to clear the media data manually?", preferredStyle: UIAlertControllerStyle.alert)
        
        // add the actions (buttons)
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { (alert) -> Void in
            self.clearMediaFromPhone()
        }))
        alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: nil))
        
        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    /**
     Save changes to the settings.
     
     - Parameters:
     - sender: The object that sent the action
     
     - Returns: void.
     */
    @IBAction func saveChangesTabBarButtonTapped(_ sender: AnyObject) {
        if !fullNameTextField.text!.isEmpty && !emailTextField.text!.isEmpty {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            if currentEmail == emailTextField.text! {
                let email = self.emailTextField.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                let fullName = self.fullNameTextField.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
                let currentDate = Date()
                let timeStamp = Int(currentDate.timeIntervalSince1970)
                
                let userData = [
                    "email": email,
                    "fullName": fullName,
                    "measuringSystem": self.measuringSystem,
                    "updatedAt": timeStamp
                    ] as [String : Any]
                
                let dBase = Firestore.firestore()
                let userRef = dBase.collection("users").document(self.currentUser!)
                
                userRef.updateData(userData) { err in
                    if let err = err {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        
                        self.displayCommonalityGenericAlert("Error!", userMessage: "There was an error saving your data. Please try again.")
                    } else {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        
                        self.displayCommonalityGenericAlertAndMoveBack("Changes Saved", userMessage: "Your changes were successfully saved.")
                    }
                }
            } else {
                Database.database().reference().child("user").queryOrdered(byChild: "email").queryEqual(toValue: emailTextField.text!).observeSingleEvent(of: .value, with: { (snapshot) in
                    /// Get a snapshot of all the child nodes i.e. messages
                    if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                        if snapshot.count > 0 {
                            self.displayMyAlertMessage("Email exists", userMessage: "The email you picked is already in use. Please try another one.")
                            return
                        } else {
                            Auth.auth().currentUser?.updateEmail(to: self.emailTextField.text!) { (error) in
                                if error == nil {
                                    let email = self.emailTextField.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                    let fullName = self.fullNameTextField.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                    
                                    let currentDate = Date()
                                    let timeStamp = Int(currentDate.timeIntervalSince1970)
                                    
                                    let userData = [
                                        "email": email,
                                        "fullName": fullName,
                                        "measuringSystem": self.measuringSystem,
                                        "updatedAt": timeStamp
                                        ] as [String : Any]
                                    
                                    let dBase = Firestore.firestore()
                                    let userRef = dBase.collection("users").document(self.currentUser!)
                                    
                                    userRef.updateData(userData) { err in
                                        if let err = err {
                                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                            
                                            self.displayCommonalityGenericAlert("Error!", userMessage: "There was an error saving your data. Please try again.")
                                        } else {
                                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                            
                                            self.displayCommonalityGenericAlertAndMoveBack("Changes Saved", userMessage: "Your changes were successfully saved.")
                                        }
                                    }
                                } else {
                                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                    self.displayMyAlertMessage("Error", userMessage: (error?.localizedDescription)!)
                                }
                            }
                        }
                    }
                })
            }
        } else {
            self.displayMyAlertMessage("Missing field(s)", userMessage: "All fields must be filled.")
        }
        
        if popupSwitch.isOn {
            KeychainWrapper.standard.set(ApplicationConstants.commonalitySmallYesValue, forKey: "commonalityShowPopups")
        } else {
            KeychainWrapper.standard.set(ApplicationConstants.commonalitySmallNoValue, forKey: "commonalityShowPopups")
        }
    }
    
    /**
     This saves the current user's device token and ARN.
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func saveCurrentDeviceToken() {
        let deviceToken = KeychainWrapper.standard.string(forKey: "commonalityMessagingToken")
        
        /// Check that there aren't any nils
        if (deviceToken != nil) {
            let userData = [
                "deviceTokenFirebase": deviceToken!
                ] as [String : Any]
            
            let dBase = Firestore.firestore()
            let userRef = dBase.collection("users").document(self.currentUser!)
            userRef.updateData(userData)
        }
    }
    
    /**
     This saves the current user's device token and ARN.
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func saveCurrentDeviceTokenAndArn() {
        let deviceToken = UserDefaults.standard.object(forKey: "deviceTokenForSNS") as? String
        let deviceArn = UserDefaults.standard.object(forKey: "endpointArnForSNS") as? String
        
        /// Check that there aren't any nils
        if (deviceToken != nil) && (deviceArn != nil) {
            let userData = [
                "deviceArn": deviceArn!,
                "deviceTokenSNS": deviceToken!
                ] as [String : Any]
            
            let dBase = Firestore.firestore()
            let userRef = dBase.collection("users").document(self.currentUser!)
            userRef.updateData(userData)
        }
    }
    
    /**
     Count the number of unread messages
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func countUnreadMessages() {
        if currentUser != nil {
            let dBase = Firestore.firestore()
            
            let userMessageRef = dBase.collection("users").document(currentUser!).collection("messages")
            
            userMessageRef.getDocuments { (querySnapshot, error) in
                if error == nil {
                    if let queryDocumentSnapshot = querySnapshot?.documents {
                        self.count3 = 0
                        self.unseenMessageCount = 0
                        
                        for data in queryDocumentSnapshot {
                            
                            let userMessageDict = data.data()
                            
                            if let seen = userMessageDict["seen"] as? Bool {
                                if !seen {
                                    self.unseenMessageCount += 1
                                }
                            }
                        }
                        
                        if let tabItems = self.tabBarController?.tabBar.items as NSArray! {
                            // In this case we want to modify the badge number of the third tab:
                            let tabItem = tabItems[2] as! UITabBarItem
                            
                            if self.unseenMessageCount == 0 {
                                tabItem.badgeValue = nil
                            } else {
                                tabItem.badgeValue = "\(self.unseenMessageCount)"
                            }
                        }
                    }
                }
            }
        }
    }
    
    /**
     Count the number of unread alerts
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func countUnreadNotifications() {
        if currentUser != nil {
            let dBase = Firestore.firestore()
            
            let notificationConnectionRequestsRef = dBase.collection("notifications").document(currentUser!).collection("connectionRequests")
            
            notificationConnectionRequestsRef.getDocuments { (querySnapshot, error) in
                if error == nil {
                    if let queryDocumentSnapshot = querySnapshot?.documents {
                        self.count4 = 0
                        self.unseenAlertCount = 0
                        
                        for data in queryDocumentSnapshot {
                            
                            let connectionRequestDict = data.data()
                            
                            if let seen = connectionRequestDict["dealtWith"] as? Bool {
                                if !seen {
                                    self.unseenAlertCount += 1
                                }
                            }
                        }
                        
                        if let tabItems = self.tabBarController?.tabBar.items as NSArray! {
                            // In this case we want to modify the badge number of the third tab:
                            let tabItem = tabItems[1] as! UITabBarItem
                            
                            if self.unseenAlertCount == 0 {
                                tabItem.badgeValue = nil
                            } else {
                                tabItem.badgeValue = "\(self.unseenAlertCount)"
                            }
                        }
                    }
                }
            }
        }
    }
    
    /**
     Displays an alert.
     
     - Parameters:
     - title: The title text
     - userMessage: The message text
     
     - Returns: void.
     */
    func displayCommonalityGenericAlert(_ title: String, userMessage: String) {
        let myAlert = UIAlertController(title: title, message: userMessage, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
        myAlert.addAction(okAction)
        
        self.present(myAlert, animated: true, completion: nil)
    }
    
    func displayCommonalityGenericAlertAndMoveBack(_ title: String, userMessage: String) {
        var alert = UIAlertController(title: title, message: userMessage, preferredStyle: UIAlertControllerStyle.alert)
        
        let okAction = UIAlertAction(title:"OK", style:UIAlertActionStyle.default) { (UIAlertAction) -> Void in
            if let nav = self.navigationController {
                nav.popViewController(animated: true)
            }
        }
        
        alert.addAction(okAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "OpenPopupFromSettings") {
            weak var spvc = segue.destination as? StandardPopupViewController
            
            spvc!.selectedTabIndex = 3
            spvc!.informativeText = "Upload your profile picture by tapping \"Change your Profile Picture\"."
        }
    }
    
    @IBAction func enablePopupButtonTapped(_ sender: Any) {
        if popupSwitch.isOn {
            popupSwitch.isOn = false
        } else {
            popupSwitch.isOn = true
        }
    }
}
