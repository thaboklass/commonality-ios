//
//  EditProfileViewController.swift
//  Commonality
//
//  Created by Thabo David Klass & Mohau Mpoti on 5/4/18.
//  Copyright © 2018 Spreebie, Inc. All rights reserved.
//

import UIKit
import FirebaseFirestore

// This class helps the user edit their profile information
class EditProfileViewController: UIViewController, UITextFieldDelegate, UIViewControllerTransitioningDelegate {
    
    // MARK: - Instance Variables
    
    var scrollViewBottomInset: CGFloat = 0.0
    var currentlyActiveTextField: UITextField?
    var fullnameStr: String?
    var schoolStr: String?
    var isStudent: Bool = true
    var occupationStr: String?
    var gradeStr: String?
    
    // MARK: - Outlets
    
    @IBOutlet weak var profilePicImageView: UIImageView!
    @IBOutlet weak var fullnameTextField: UITextField!
    @IBOutlet weak var occupationTextField: UITextField!
    @IBOutlet weak var gradeTextField: UITextField!
    @IBOutlet weak var borderView: UIView!
    
    @IBOutlet weak var schoolTextField: UITextField!
    @IBOutlet weak var addPictureButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    
    @IBOutlet weak var studentRadioButton: RadioButton!
    @IBOutlet weak var teacherRadioButton: RadioButton!
    
    /// The user profile picture name
    var profilePictureFileName: String? = String()
    
    /// The current user
    var currentUser: String? = KeychainWrapper.standard.string(forKey: ApplicationConstants.commonalityUserIDKey)
    
    @IBAction func studentRadioButtonPressed(_ sender: RadioButton) {
        toggleInterfaceDisplay(isStudent: studentRadioButton.isSelected)
    }
    
    @IBAction func teacherRadioButtonPressed(_ sender: RadioButton) {
        toggleInterfaceDisplay(isStudent: studentRadioButton.isSelected)
        print("teacher pressed")
    }
    
    
    @IBOutlet weak var occupationAndGradeLabel: UILabel!

    @IBAction func saveBarButtonItemPressed(_ sender: UIBarButtonItem) {
        
        // Assign Variables
        self.fullnameStr = self.fullnameTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        self.schoolStr = self.schoolTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        self.occupationStr = self.occupationTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        self.gradeStr = self.gradeTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        
        // Validate fields
        guard !self.fullnameStr!.isEmpty else {
            let alertController = UIAlertController(title: "Alert", message: "You are required to fill in your Full Name.", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: {(alert: UIAlertAction!) in
                self.fullnameTextField.becomeFirstResponder()
            })
            
            alertController.addAction(action)
            self.present(alertController, animated: true, completion: nil)
            
            
            return
        }
        
        
        // Save data to the database here
        var role = "student"
        var roleDetails = ""
        
        if studentRadioButton.isSelected {
            role = "student"
            roleDetails = self.gradeStr!
        } else {
            role = "teacher"
            roleDetails = self.occupationStr!
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let currentDate = Date()
        let timeStamp = Int(currentDate.timeIntervalSince1970)
        
        // The dictionary data to be updated
        let userData = [
            "fullName": self.fullnameStr!,
            "school": self.schoolStr!,
            "role": role,
            "roleDetails": roleDetails,
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
                
                KeychainWrapper.standard.set(ApplicationConstants.commonalitySmallYesValue, forKey: "commonalityJustSavedProfile")
                self.displayCommonalityGenericAlertAndMoveBack("Changes Saved", userMessage: "Your changes were successfully saved.")
            }
        }
    }
    
    @IBAction func cancelBarButtonItemPressed(_ sender: UIBarButtonItem) {
        let dialogMessage = UIAlertController(title: "", message: "Discard Changes?", preferredStyle: .alert)
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        let discardButton = UIAlertAction(title: "Discard", style: .default, handler: { (action) -> Void in
            self.navigationController?.popViewController(animated: true)
        })
        
        dialogMessage.addAction(cancelButton)
        dialogMessage.addAction(discardButton)
        
        self.present(dialogMessage, animated: true, completion: nil)
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let greenish = UIColor(red: 45.0/255.0, green: 182.0/255.0, blue: 174.0/255.0, alpha: 1.0)
        
        /// This creates rounded corners for the image view
        let imageLayer: CALayer?  = self.profilePicImageView.layer
        imageLayer!.borderWidth = 2.0
        imageLayer!.borderColor = UIColor.white.cgColor
        
        imageLayer!.cornerRadius = profilePicImageView.frame.height / 2
        imageLayer!.masksToBounds = true
        
        let borderLayer: CALayer?  = self.borderView.layer
        borderLayer!.borderWidth = 2.0
        borderLayer!.borderColor = greenish.cgColor
        
        borderLayer!.cornerRadius = borderView.frame.height / 2
        borderLayer!.masksToBounds = true
        
        // Initialize the RadioButtons
        studentRadioButton.alternateButton = [teacherRadioButton!]
        teacherRadioButton.alternateButton = [studentRadioButton!]
        
        
        /* *******************  Populate UserProfile Fields from the previous screen here>>  ****************** */
        
        
        // Initialize the selection of the UserType RadioButtons, based on the value of the isStudent instance variable
        toggleInterfaceDisplay(isStudent: isStudent)
        if isStudent {
            studentRadioButton.isSelected = true
            teacherRadioButton.isSelected = false
        } else {
            studentRadioButton.isSelected = false
            teacherRadioButton.isSelected = true
        }
        
        fullnameTextField.text = fullnameStr ?? ""
        schoolTextField.text = schoolStr ?? ""
        occupationTextField.text = occupationStr ?? ""
        gradeTextField.text = gradeStr ?? ""
        
        /* *******************  End  ****************** */
        
        /// So the textfield delegate functions work
        fullnameTextField.delegate = self
        occupationTextField.delegate = self
        gradeTextField.delegate = self
        schoolTextField.delegate = self
        
        
        // Change the appearance of the Add Picture Button
        
        let purplish = UIColor(red: 192.0/255.0, green: 30.0/255.0, blue: 201.0/255.0, alpha: 1.0)
        addPictureButton.layer.backgroundColor = UIColor.white.cgColor
        addPictureButton.setTitleColor(purplish, for: .normal)
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        // Set the user data
        setUserData()
    }
    
    override func viewDidLayoutSubviews() {
        // Assign the initial value of the ContentView's bottom inset. This will be used as a point of reference (to re-position back to) when scrolling programatically
        scrollViewBottomInset = scrollView.contentInset.bottom
        
        view.frame.size.height = 800
        scrollView.contentSize.height = 1200
        scrollView.contentSize.width = view.frame.width
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        scrollView.setContentOffset(CGPoint(x: 0, y: -self.scrollView.contentInset.top), animated: true)
        
        // Create Observers to listen-in when the device keyboard appears or hides
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(notification:)), name: .UIKeyboardWillChangeFrame, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
        
        // In case the page has been opened before
        currentUser = KeychainWrapper.standard.string(forKey: ApplicationConstants.commonalityUserIDKey)
        
        /// If the current user is not nil...
        if currentUser != nil {
            setUserData()
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        
        view.addGestureRecognizer(tap)
    }
    
    // Dismisses the keyboard
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - TextField Delegate Methods
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        currentlyActiveTextField = textField
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // This enables the return key to hide the keyboard
        textField.resignFirstResponder()
        
        return true
    }
    
    
    // MARK: - Helpers
    
    // Segues back
    @objc func goBack() {
        let dialogMessage = UIAlertController(title: "", message: "Discard Changes?", preferredStyle: .alert)
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        let discardButton = UIAlertAction(title: "Discard", style: .default, handler: { (action) -> Void in
            self.navigationController?.popViewController(animated: true)
        })
        
        dialogMessage.addAction(cancelButton)
        dialogMessage.addAction(discardButton)
        
        self.present(dialogMessage, animated: true, completion: nil)
    }
    
    
    // Return the ScrollView's ContentView to its original inset configurations when the keyboard hides
    @objc func keyboardWillHide(notification: Notification) {
        
        scrollView.setContentOffset(CGPoint(x: 0, y: -self.scrollView.contentInset.top), animated: true)
        self.scrollView.contentInset.bottom = self.scrollViewBottomInset
    }
    
    
    // if the keyboard's CGRect intersects with the CGRect of the TextField being edited, re-adjust the position of the ScrollView by changing the bottom inset of its ContentView
    @objc func keyboardWillChangeFrame(notification: Notification) {
        if let textField = currentlyActiveTextField {
            
            if let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect {
                // Convert the CGrect/Rectangle of the keyboard's coordinate system to that of the ScrollView's ContentView
                let convertedKeyboardFrame = self.view.convert(keyboardFrame, to: self.contentView)
                
                if convertedKeyboardFrame.intersects(textField.frame) {
                    
                    // Re-adjust the position of the ContentView's bottom inset here>>
                    self.scrollView.contentInset.bottom = convertedKeyboardFrame.size.height
                    
                }
            }
        }
    }
    
    /**
     This toggles the textfield that are layered on top of one another
     and displays them based on the situation
     
     - Parameters:
     - isStudent: A boolean - is the user a student or not
     
     - Returns: nothing.
     */
    func toggleInterfaceDisplay(isStudent: Bool) -> Void {
        if isStudent {
            // Display the Grade TextField
            occupationAndGradeLabel.text = "Grade"
            gradeTextField.isHidden = false
            
            occupationTextField.isHidden = true
        } else {
            //Display the Occupation TextField
            occupationAndGradeLabel.text = "Occupation"
            gradeTextField.isHidden = true
            
            occupationTextField.isHidden = false
        }
    }
    
    
    /**
     Sets the user data into the table.
     
     - Parameters:
     - none:
     
     - Returns: void.
     */
    func setUserData() {
        /// Check for nil
        if currentUser != nil {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            // Get firestore dBase
            let dBase = Firestore.firestore()
            
            let userRef = dBase.collection("users").document(currentUser!)
            
            userRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    if let userDict = document.data() {
                        /// Check for nil again
                        if userDict != nil {
                            /// Check for nil again
                            if let fullName = userDict["fullName"] as? String, let profilePictureFileName = userDict["profilePictureFileName"] as? String {
                                
                                /// Set the text data
                                self.fullnameTextField.text = fullName
                                
                                /// Set the profile picture data
                                if profilePictureFileName != ApplicationConstants.dbEmptyValue {
                                    self.profilePictureFileName = profilePictureFileName
                                    self.setProfilePicture()
                                }
                                
                                if let school = userDict["school"] as? String {
                                    self.schoolTextField.text = school
                                }
                                
                                if let role = userDict["role"] as? String {
                                    if role == "student" {
                                        self.studentRadioButton.isSelected = true
                                        self.teacherRadioButton.isSelected = false
                                        
                                        if let roleDetails = userDict["roleDetails"] as? String {
                                            self.toggleInterfaceDisplay(isStudent: true)
                                            self.gradeTextField.text = roleDetails
                                        }
                                    } else {
                                        self.studentRadioButton.isSelected = false
                                        self.teacherRadioButton.isSelected = true
                                        
                                        if let roleDetails = userDict["roleDetails"] as? String {
                                            self.toggleInterfaceDisplay(isStudent: false)
                                            self.occupationTextField.text = roleDetails
                                        }
                                    }
                                }
                                
                                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                            }
                        }
                    }
                } else {
                    print("Error: \(String(describing: error?.localizedDescription))")
                }
            }
        }
    }
    
    /// Set the profile picture
    func setProfilePicture() {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
        let documentDirectoryURL = URL(fileURLWithPath: documentDirectory)
        
        if let ppFileName = self.profilePictureFileName {
            
            let downloadSmallFileURL = documentDirectoryURL.appendingPathComponent(ppFileName)
            
            if FileManager.default.fileExists(atPath: downloadSmallFileURL.path) {
                self.insertProfilePic(self.profilePicImageView, fileName: ppFileName, downloadFileURL: downloadSmallFileURL)
            } else {
                self.downloadProfilePic(self.profilePicImageView, fileName: self.profilePictureFileName!, downloadFileURL: downloadSmallFileURL)
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
    
    
    /**
     Displays an alert and segues back.
     
     - Parameters:
     - title: The title text
     - userMessage: The message text
     
     - Returns: void.
     */
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
}

