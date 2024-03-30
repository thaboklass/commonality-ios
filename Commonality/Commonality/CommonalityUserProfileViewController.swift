//
//  CommonalityUserProfileViewController.swift
//  Commonality
//
//  Created by Thabo David Klass on 06/06/2018.
//  Copyright © 2018 Spreebie, Inc. All rights reserved.
//

import UIKit
import FirebaseFirestore
import AWSSNS

// Commonality user profile class
class CommonalityUserProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // The class outlets
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var nudgeButton: UIButton!
    @IBOutlet weak var statusTextView: UITextView!
    @IBOutlet weak var profileTableView: UITableView!
    @IBOutlet weak var connectSaveButton: UIButton!
    @IBOutlet weak var userBackgroundView: UIView!
    @IBOutlet weak var borderView: UIView!
    
    /// The current user
    var currentUser: String? = KeychainWrapper.standard.string(forKey: ApplicationConstants.commonalityUserIDKey)
    
    /// The current user name
    var currentUserName: String? = nil
    
    // The picked user
    var pickedUser: String? = nil
    
    /// The user profile picture name
    var profilePictureFileName = ApplicationConstants.dbEmptyValue
    
    // The list of connections
    var currentUserConnections = [String]()
    var pickedUserConnections = [String]()
    
    /// The message ID
    var messageID: String!
    
    /// The count
    var count: Int = 0
    
    /// The requested users
    var requestedUsers = [String]()
    
    /// If there is a connection request, the ID is
    var cancelConnectionRequestID: String? = nil
    
    /// If there is a connection request, the ID is
    var acceptConnectionRequestID: String? = nil
    
    /// Counters
    var unseenAlertCount: Int = 0
    var unseenMessageCount: Int = 0
    
    
    /// Progress animation
    let shapeLayer = CAShapeLayer()
    let trackLayer = CAShapeLayer()
    
    let percentageLabel: UILabel = {
        let label = UILabel()
        label.text = "0%"
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 32)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Select the current ViewController as the TableView's delegate and datasource
        profileTableView.delegate = self
        profileTableView.dataSource = self
        
        chatButton.isEnabled = false
        
        /// Rounded corners
        let imageLayer: CALayer?  = self.profilePictureImageView.layer
        imageLayer!.cornerRadius = self.profilePictureImageView.frame.height / 2
        imageLayer!.masksToBounds = true
        
        let purplish = UIColor(red: 192.0/255.0, green: 30.0/255.0, blue: 201.0/255.0, alpha: 1.0)
        
        profilePictureImageView.layer.borderWidth = 5
        profilePictureImageView.layer.borderColor = UIColor.white.cgColor
        
        
        let borderLayer: CALayer?  = self.borderView.layer
        borderLayer!.cornerRadius = self.borderView.frame.height / 2
        borderLayer!.masksToBounds = true
        
        borderView.layer.borderWidth = 5
        borderView.layer.borderColor = purplish.cgColor
        
        let statusTextViewLayer: CALayer?  = statusTextView.layer
        statusTextViewLayer!.cornerRadius = chatButton.frame.height / 4
        statusTextViewLayer!.masksToBounds = true
        
        let connectSaveButtonLayer: CALayer?  = connectSaveButton.layer
        connectSaveButtonLayer!.cornerRadius = 4
        connectSaveButtonLayer!.masksToBounds = true
        
        let userBackgroundViewLayer: CALayer?  = userBackgroundView.layer
        userBackgroundViewLayer!.cornerRadius = chatButton.frame.height / 4
        userBackgroundViewLayer!.masksToBounds = true
        
        let greyishLight = UIColor(red: 170.0/255.0, green: 170.0/255.0, blue: 170.0/255.0, alpha: 0.3)
        
        userBackgroundView.layer.borderWidth = 3
        userBackgroundView.layer.borderColor = greyishLight.cgColor
        
        let nudgeButtonLayer: CALayer?  = nudgeButton.layer
        nudgeButtonLayer!.cornerRadius = 4
        nudgeButtonLayer!.masksToBounds = true
        
        /// Keyboard mitigation
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        tap.cancelsTouchesInView = false
        
        if pickedUser != nil {
            if currentUser != nil {
                if currentUser != pickedUser {
                    statusTextView.isEditable = false
                    editButton.isEnabled = false
                    
                    settingsButton.isEnabled = false
                    
                    connectSaveButton.isEnabled = false
                    
                    if currentUserConnections.count > 0 {
                        if containsConnection() {
                            connectSaveButton.isEnabled = true
                            connectSaveButton.setTitle("DISCONNECT", for: .normal)
                        }
                    }
                    
                    checkForRequests()
                } else {
                    chatButton.isEnabled = false
                    nudgeButton.isEnabled = false
                    connectSaveButton.setTitle("SAVE", for: .normal)
                }
                
                setMessageID()
                getConnections()
            }
            
            setUserData()
        }
        
        /// Animation
        let circularPath = UIBezierPath(arcCenter: .zero, radius: 80, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        trackLayer.path = circularPath.cgPath
        
        trackLayer.strokeColor = UIColor.lightGray.cgColor
        trackLayer.lineWidth = 10
        trackLayer.fillColor = UIColor.white.cgColor
        trackLayer.lineCap = kCALineCapRound
        trackLayer.position = profilePictureImageView.center
        
        scrollView.layer.addSublayer(trackLayer)
        
        shapeLayer.path = circularPath.cgPath
        
        let lightGreeen = UIColor(red: 41.0/255.0, green: 169.0/255.0, blue: 158.0/255.0, alpha: 1.0)
        shapeLayer.strokeColor = lightGreeen.cgColor
        shapeLayer.lineWidth = 10
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineCap = kCALineCapRound
        shapeLayer.position = profilePictureImageView.center
        
        shapeLayer.transform = CATransform3DMakeRotation(-CGFloat.pi / 2, 0, 0, 1)
        
        shapeLayer.strokeEnd = 0
        
        scrollView.layer.addSublayer(shapeLayer)
        
        scrollView.addSubview(percentageLabel)
        percentageLabel.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        percentageLabel.center = profilePictureImageView.center
        
        percentageLabel.textColor = purplish
        
        percentageLabel.isHidden = true
        trackLayer.isHidden = true
        shapeLayer.isHidden = true
    }
    
    /// Keyboard mitigation
    @objc func keyboardWillShow(notify: NSNotification) {
        if let keyboardSize = (notify.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height / 2
            }
        }
    }
    
    @objc func keyboardWillHide(notify: NSNotification) {
        if let keyboardSize = (notify.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0 {
                self.view.frame.origin.y += keyboardSize.height / 2
            }
        }
    }
    
    // dismiss the keyboard
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        scrollView.contentSize.height = 700
        scrollView.contentSize.width = view.frame.width
    }
    
    
    /**
     Downloads the profile pic.
     
     - Parameters:
     - imageView: The profile pic image view
     - fileName: The name of the file as it is store on S3
     - downloadULR: The local storage url
     
     - Returns: void.
     */
    func setProfilePic() {
        /// When signing up, the user image is stored as "empty"
        if profilePictureFileName != ApplicationConstants.dbEmptyValue {
            shapeLayer.strokeEnd = 0
            
            percentageLabel.isHidden = false
            trackLayer.isHidden = false
            shapeLayer.isHidden = false
            
            /// Get a reference to the image using the URL
            let ref = Storage.storage().reference(forURL: self.profilePictureFileName)
            
            let fileNameToSaveAs = "profile_" + currentUser! + ".jpg"
            
            /// The directory of the documents folder
            let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
            
            /// The URL of the documents folder
            let documentDirectoryURL = URL(fileURLWithPath: documentDirectory)
            
            /// The local URL of the profile pic
            let localURL = documentDirectoryURL.appendingPathComponent(fileNameToSaveAs)
            
            let downloadTask = ref.write(toFile: localURL)
            
            downloadTask.observe(.progress) { snapshot in
                let percentCompleteDouble = 100.0 * Double(snapshot.progress!.completedUnitCount)
                    / Double(snapshot.progress!.totalUnitCount)
                if !percentCompleteDouble.isNaN {
                    let percentComplete = Int(percentCompleteDouble)
                    print("Done: \(percentComplete)%")
                    
                    let progress = Double(snapshot.progress!.completedUnitCount)
                        / Double(snapshot.progress!.totalUnitCount)

                    self.percentageLabel.text = "\(percentComplete)%"
                    self.shapeLayer.strokeEnd = CGFloat(progress)
                    
                }
            }
            
            downloadTask.observe(.success) { snapshot in
                // Download completed successfully
                print("Downloaded successfully")
                self.percentageLabel.isHidden = true
                self.trackLayer.isHidden = true
                self.shapeLayer.isHidden = true
                
                if let image = UIImage(contentsOfFile: localURL.path) {
                    self.profilePictureImageView.alpha = 0
                    
                    self.profilePictureImageView.image = image
                    UIView.animate(withDuration: 0.5, animations: { () -> Void in
                        self.profilePictureImageView.alpha = 1
                    })
                }
            }
        }
    }
    
    /**
     Set the user's data.
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func setUserData() {
        /// Check for nil
        if pickedUser != nil {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            // Get firestore dBase
            let dBase = Firestore.firestore()
            
            let userRef = dBase.collection("users").document(pickedUser!)
            
            userRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    if let userDict = document.data() {
                        /// Check for nil again
                        if let fullName = userDict["fullName"] as? String, let profilePictureFileName = userDict["profilePictureFileName"] as? String {
                            /// Set the text data
                            self.userNameLabel.text = fullName
                            
                            /// Set the profile picture data
                            if profilePictureFileName != ApplicationConstants.dbEmptyValue {
                                self.profilePictureFileName = profilePictureFileName
                                self.setProfilePic()
                            }
                            
                            if let status = userDict["status"] as? String {
                                self.statusTextView.text = status
                            }
                            
                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        }
                    }
                } else {
                    print("Error: \(String(describing: error?.localizedDescription))")
                }
            }
        }
    }
    
    
    // The connect and save button action
    @IBAction func connectSaveButtonTapped(_ sender: Any) {
        if connectSaveButton.titleLabel?.text! == "SAVE" {
            let status = statusTextView.text?.trimmingCharacters(in: .whitespaces) ?? ""
            
            if isTextViewEmpty(textView: statusTextView) {
                let alertController = UIAlertController(title: "Empty Status", message: "To save your status, please fill the field first.", preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default, handler: {(alert: UIAlertAction!) in
                    self.statusTextView.becomeFirstResponder()
                })
                
                alertController.addAction(action)
                self.present(alertController, animated: true, completion: nil)
            } else {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                
                let userData = [
                    "status": status
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
            }
        } else if connectSaveButton.titleLabel?.text! == "CONNECT" {
            let alert = UIAlertController(title: "Connection request", message: "Once you are connected, you will be able to message each other even when you're not around each other. Do you want to continue?", preferredStyle: UIAlertControllerStyle.alert)
            
            // add the actions (buttons)
            alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { (alert) -> Void in
                // Connect the users
                self.requestConnection()
            }))
            alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: nil))
            
            // show the alert
            self.present(alert, animated: true, completion: nil)
        } else if connectSaveButton.titleLabel?.text! == "CANCEL" {
            let alert = UIAlertController(title: "Cancel request", message: "Are you sure you want to cancel your connection request?", preferredStyle: UIAlertControllerStyle.alert)
            
            // add the actions (buttons)
            alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { (alert) -> Void in
                // Connect the users
                self.cancelRequest()
            }))
            alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: nil))
            
            // show the alert
            self.present(alert, animated: true, completion: nil)
        } else if connectSaveButton.titleLabel?.text! == "ACCEPT" {
            connectSaveButton.setTitle("DISCONNECT", for: .normal)
            connectSaveButton.isEnabled = false
            connect()
        }  else {
            let alert = UIAlertController(title: "Disconnect?", message: "Are you sure that you want to disconnect?", preferredStyle: UIAlertControllerStyle.alert)
            
            // add the actions (buttons)
            alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { (alert) -> Void in
                // Connect the users
                self.disconnect()
            }))
            alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: nil))
            
            // show the alert
            self.present(alert, animated: true, completion: nil)
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
    
    /**
     Displays an alert and move back.
     
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 //sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var numberOfRows: Int = 2
        
        return numberOfRows
    }
    
    
    
    
    // Set the table row height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 47
    }
    
    fileprivate struct Storyboard {
        // This value needs to be set in the attributes inspector properties section of the table cell, in the storyboard
        static let CellReuseIdentifier = "CommonalityUserProfileCell"
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.CellReuseIdentifier, for: indexPath) as! CommonalityUserProfileTableViewCell
        
        cell.selectionStyle = .none
        
        let commonalityMetaBackgroundLayer: CALayer?  = cell.commonalityMetaBackground.layer
        commonalityMetaBackgroundLayer!.cornerRadius = 4
        commonalityMetaBackgroundLayer!.masksToBounds = true
        
        if indexPath.row == 0 {
            cell.commonalityIcon.image = #imageLiteral(resourceName: "messages_profile_icon")
            cell.commonalityTitle.text = "Messages"
            cell.commonalityMeta.text = "0"
            
            if currentUser == pickedUser {
                // Count the unread messages
                countUnreadMessages(label: cell.commonalityMeta)
            } else {
                cell.commonalityMeta.text = "-"
            }
        } else {
            cell.commonalityIcon.image = #imageLiteral(resourceName: "requests_profile_icon")
            cell.commonalityTitle.text = "Requests"
            cell.commonalityMeta.text = "0"
            
            if currentUser == pickedUser {
                // Count the unread alerts
                countUnreadNotifications(label: cell.commonalityMeta)
            } else {
                cell.commonalityMeta.text = "-"
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if currentUser == pickedUser {
            if indexPath.row == 0 {
                self.performSegue(withIdentifier: "OpenMessagesFromProfile", sender: nil)
            } else {
                self.performSegue(withIdentifier: "OpenNotificationsFromProfile", sender: nil)
            }
        }
    }
    
    
    /**
     Connects a user with another.
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func connect() {
        if acceptConnectionRequestID != nil {
            currentUserConnections.append(pickedUser!)
            
            let userData: [String: Any] = [
                "connectionList": currentUserConnections
            ]
            
            let dBase = Firestore.firestore()
            
            dBase.collection("connections").document(currentUser!).setData(userData) { (error) in
                if let error = error {
                    print("\(error.localizedDescription)")
                } else {
                    self.pickedUserConnections.append(self.currentUser!)
                    
                    let userData2: [String: Any] = [
                        "connectionList": self.pickedUserConnections
                    ]
                    
                    dBase.collection("connections").document(self.pickedUser!).setData(userData2) { (error) in
                        if let error = error {
                            print("\(error.localizedDescription)")
                        } else {
                            let requestData = [
                                "dealtWith": true
                                ] as [String : Any]
                            
                            let connectionRequestRef = dBase.collection("notifications").document(self.currentUser!).collection("connectionRequests").document(self.acceptConnectionRequestID!)
                            
                            connectionRequestRef.updateData(requestData)
                            
                            self.connectSaveButton.setTitle("DISCONNECT", for: .normal)
                            self.displayCommonalityGenericAlertAndMoveBack("Connected!", userMessage: "Congratulations! You are now connected.")
                        }
                    }
                }
            }
        }
    }
    
    
    /**
     Request a connection with another user.
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func requestConnection() {
        if pickedUser != nil && currentUser != nil {
            /// Create the unix time stamp
            let currentDate = Date()
            let timeStamp = Int(currentDate.timeIntervalSince1970)
            
            if currentUserName != nil {
                let notificationData: [String: Any] = [
                    "actor": currentUser!,
                    "actorName": currentUserName!,
                    "notificationType": "connectionRequest",
                    "dealtWith": false,
                    "creationAt": timeStamp,
                    "updatedAt": timeStamp
                ]
                
                let dBase = Firestore.firestore()
                
                dBase.collection("notifications").document(pickedUser!).collection("connectionRequests").addDocument(data: notificationData) { (error) in
                    if let error = error {
                        print("\(error.localizedDescription)")
                    } else {
                        // Set button requested or cancel
                        self.connectSaveButton.setTitle("CANCEL", for: .normal)
                        
                        // Send push notification
                        self.sendConnectionRequestPushNotification()
                        
                        // Display alert
                        self.displayCommonalityGenericAlertAndMoveBack("Requested", userMessage: "Your connection request has been sent. Please wait to get a response.")
                    }
                }
            }
        }
    }
    
    
    /**
     Disconnect a user with another.
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func disconnect() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        var count = 0
        
        for currentUserConnection in currentUserConnections {
            if currentUserConnection == pickedUser! {
                currentUserConnections.remove(at: count)
            }
            
            count += 1
        }
        
        let userData = [
            "connectionList": currentUserConnections
        ] as [String : Any]
        
        let dBase = Firestore.firestore()
        let userRef = dBase.collection("connections").document(self.currentUser!)
        
        userRef.updateData(userData) { err in
            if let err = err {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                self.displayCommonalityGenericAlert("Error!", userMessage: "There was an error saving your data. Please try again.")
            } else {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                var count = 0
                
                for pickedUserConnection in self.pickedUserConnections {
                    if pickedUserConnection == self.currentUser! {
                        self.pickedUserConnections.remove(at: count)
                    }
                    
                    count += 1
                }
                
                let userData2 = [
                    "connectionList": self.pickedUserConnections
                ] as [String : Any]

                
                let userRef2 = dBase.collection("connections").document(self.pickedUser!)
                userRef2.updateData(userData2) { err in
                    if let err = err {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        
                        self.displayCommonalityGenericAlert("Error!", userMessage: "There was an error saving your data. Please try again.")
                    } else {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        
                        self.displayCommonalityGenericAlertAndMoveBack("Disconnected", userMessage: "You have succesfully updated the connections.")
                    }
                }
            }
        }
    }
    
    // Check if the observed user is connected with the current user
    func containsConnection() -> Bool {
        for connection in currentUserConnections {
            if connection == pickedUser! {
                return true
            }
        }
        
        return false
    }
    
    
    /**
     Get the connections list.
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func getConnections() {
        /// Check for nil
        if currentUser != nil {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            // Get firestore dBase
            let dBase = Firestore.firestore()
            
            let connectionRef = dBase.collection("connections").document(pickedUser!)
            
            connectionRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    if let connectionDict = document.data() {
                        /// Check for nil again
                        if let cnxs = connectionDict["connectionList"] as? [String] {
                            // Assign the connections if the exist
                            self.pickedUserConnections = cnxs
                            
                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        }
                    }
                } else {
                    print("Error: \(String(describing: error?.localizedDescription))")
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "OpenMessageFromButtonClick") {
            weak var mvc = segue.destination as? MessagesViewController
            
            mvc!.recipient = pickedUser!
            mvc!.messageID = messageID
            mvc!.recipientName = userNameLabel.text!
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "OpenMessageFromButtonClick" {
            if currentUser == nil {
                return false
            }
            
            if pickedUser == nil {
                return false
            }
            
            if currentUser == pickedUser {
                return false
            }
        }
        
        return true
    }
    
    
    /**
     This sets the message ID between the two users if
     it exists on viewDidLoad. If it does not exist, it
     will remain nil
     
     - Parameters:
     - title: The title text
     - userMessage: The message text
     
     - Returns: void.
     */
    func setMessageID() {
        messageID = nil
        
        if pickedUser != nil && currentUser != nil {
            if pickedUser! != currentUser! {
                let dBase = Firestore.firestore()
                
                let messageRef = dBase.collection("users").document(currentUser!).collection("messages")
                
                messageRef.getDocuments { (querySnapshot, error) in
                    if error == nil {
                        if let queryDocumentSnapshot = querySnapshot?.documents {
                            if queryDocumentSnapshot.count == 0 {
                                self.chatButton.isEnabled = true
                            }
                            
                            var userWithExistingConversationFound = false
                            
                            for data in queryDocumentSnapshot {
                                self.messageID = data.documentID
                                
                                let messageDict = data.data()
                                
                                if let recipientID = messageDict["recipient"] as? String {
                                    if recipientID == self.pickedUser! {
                                        userWithExistingConversationFound = true
                                        self.chatButton.isEnabled = true
                                        
                                        break
                                    }
                                }
                                
                                if !userWithExistingConversationFound {
                                    self.chatButton.isEnabled = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // This verfies if the text view is empty
    func isTextViewEmpty(textView: UITextView) -> Bool {
        guard let text = textView.text,
            !text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty else {
                // this will be reached if the text is nil (unlikely)
                // or if the text only contains white spaces
                // or no text at all
                return true
        }
        
        return false
    }
    
    
    /**
     This sends the connection request push notification.
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func sendConnectionRequestPushNotification() {
        /// Check for nil
        if pickedUser != nil {
            /// Get the user reference
            let dBase = Firestore.firestore()
            let messageRef = dBase.collection("users").document(pickedUser!)
            
            messageRef.getDocument { (querySnapshot, error) in
                if error == nil {
                    if let userDict = querySnapshot?.data() {
                        if let deviceArn = userDict["deviceArn"] as? String, let deviceTokenSNS = userDict["deviceTokenSNS"] as? String {
                            
                            /// Push notification meant for the spreebie uploader
                            let sns = AWSSNS.default()
                            let request = AWSSNSPublishInput()
                            
                            request?.messageStructure = "json"
                            
                            /// The payload
                            let dict = ["default": "You have received a new connection request. View it on your notifications.", ApplicationConstants.commonalityAPNSType: "{\"aps\":{\"alert\": {\"title\":\"New connection request\",\"body\":\"You have received a new connection request. View it on your notifications.\"},\"sound\":\"default\",\"badge\":1} }"]
                            
                            do {
                                let jsonData = try JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions.prettyPrinted)
                                request?.message = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue) as? String
                                
                                request?.targetArn = deviceArn
                                
                                sns.publish(request!).continueWith
                                    {
                                        (task) -> AnyObject! in
                                        if task.error != nil
                                        {
                                            print("Error sending mesage: \(String(describing: task.error))")
                                        }
                                        else
                                        {
                                            print("Success sending message")
                                        }
                                        return nil
                                }
                            } catch {
                                
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    /**
     Check if there are any connection requests.
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func checkForRequests() {
        if pickedUser != nil {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            self.count = 0
            requestedUsers.removeAll()
            
            // Get firestore dBase
            let dBase = Firestore.firestore()
            
            let pickedUserRequestsRef = dBase.collection("notifications").document(pickedUser!).collection("connectionRequests")
            
            pickedUserRequestsRef.getDocuments { (querySnapshot, error) in
                if error == nil {
                    if let snapshot = querySnapshot {
                        /// Enable the button
                        self.connectSaveButton.isEnabled = true
                        
                        let documents = snapshot.documents
                        
                        for document in documents {
                            let requestDict = document.data()
                            let key = document.documentID
                            
                            if let dealtWith = requestDict["dealtWith"] as? Bool, let actor = requestDict["actor"] as? String {
                                if !dealtWith {
                                    print(actor)
                                    print(self.currentUser!)
                                    if actor == self.currentUser! {
                                        self.cancelConnectionRequestID = key
                                        self.connectSaveButton.setTitle("CANCEL", for: .normal)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            let currentUserRequestsRef = dBase.collection("notifications").document(currentUser!).collection("connectionRequests")
            
            currentUserRequestsRef.getDocuments { (querySnapshot, error) in
                if error == nil {
                    if let snapshot = querySnapshot {
                        /// Enable the button
                        self.connectSaveButton.isEnabled = true
                        
                        let documents = snapshot.documents
                        
                        for document in documents {
                            let requestDict = document.data()
                            let key = document.documentID
                            
                            if let dealtWith = requestDict["dealtWith"] as? Bool, let actor = requestDict["actor"] as? String {
                                if !dealtWith {
                                    print(actor)
                                    print(self.pickedUser!)
                                    if actor == self.pickedUser! {
                                        self.acceptConnectionRequestID = key
                                        self.connectSaveButton.setTitle("ACCEPT", for: .normal)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    /**
     Cancel the sent request.
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func cancelRequest() {
        if cancelConnectionRequestID != nil {
            let userData = [
                "dealtWith": true
                ] as [String : Any]
            
            let dBase = Firestore.firestore()
            let connectionRequestRef = dBase.collection("notifications").document(pickedUser!).collection("connectionRequests").document(cancelConnectionRequestID!)
            
            connectionRequestRef.updateData(userData) { err in
                if let err = err {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    
                    self.displayCommonalityGenericAlert("Error!", userMessage: "There was an error saving your data. Please try again.")
                } else {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    
                    self.displayCommonalityGenericAlertAndMoveBack("Request Cancelled", userMessage: "Your connection request was cancelled.")
                }
            }
        }
    }
    
    
    /**
     This sends the nudge push notification.
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func sendNudgePushNotification() {
        /// Check for nil
        if pickedUser != nil {
            /// Get the user reference
            let dBase = Firestore.firestore()
            let messageRef = dBase.collection("users").document(pickedUser!)
            
            messageRef.getDocument { (querySnapshot, error) in
                if error == nil {
                    if let userDict = querySnapshot?.data() {
                        if let deviceArn = userDict["deviceArn"] as? String, let deviceTokenSNS = userDict["deviceTokenSNS"] as? String {
                            
                            /// Push notification meant for the spreebie uploader
                            let sns = AWSSNS.default()
                            let request = AWSSNSPublishInput()
                            
                            request?.messageStructure = "json"
                            
                            /// The payload
                            let dict = ["default": "You have received a new nudge. View it on your notifications.", ApplicationConstants.commonalityAPNSType: "{\"aps\":{\"alert\": {\"title\":\"New nudge\",\"body\":\"You have received a new nudge. View it on your notifications.\"},\"sound\":\"default\",\"badge\":1} }"]
                            
                            do {
                                let jsonData = try JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions.prettyPrinted)
                                request?.message = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue) as? String
                                
                                request?.targetArn = deviceArn
                                
                                sns.publish(request!).continueWith
                                    {
                                        (task) -> AnyObject! in
                                        if task.error != nil
                                        {
                                            print("Error sending mesage: \(String(describing: task.error))")
                                        }
                                        else
                                        {
                                            print("Success sending message")
                                        }
                                        return nil
                                }
                            } catch {
                                
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    /**
     This performs a nudge.
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func nudge() {
        if pickedUser != nil && currentUser != nil {
            /// Create the unix time stamp
            let currentDate = Date()
            let timeStamp = Int(currentDate.timeIntervalSince1970)
            
            if currentUserName != nil {
                let notificationData: [String: Any] = [
                    "actor": currentUser!,
                    "actorName": currentUserName!,
                    "notificationType": "nudge",
                    "dealtWith": false,
                    "creationAt": timeStamp,
                    "updatedAt": timeStamp
                ]
                
                let dBase = Firestore.firestore()
                
                dBase.collection("notifications").document(pickedUser!).collection("nudges").addDocument(data: notificationData) { (error) in
                    if let error = error {
                        print("\(error.localizedDescription)")
                    } else {
                        // Send push notification
                        self.sendNudgePushNotification()
                        
                        // Display alert
                        self.displayCommonalityGenericAlertAndMoveBack("Nudged", userMessage: "Your have made a successful nudge. Wait for a response.")
                    }
                }
            }
        }
    }
    
    // The nudge button action
    @IBAction func nudgeButtonTapped(_ sender: Any) {
        nudge()
    }
    
    /**
     Count the number of unread messages
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func countUnreadMessages(label: UILabel) {
        if currentUser != nil {
            let dBase = Firestore.firestore()
            
            let userMessageRef = dBase.collection("users").document(currentUser!).collection("messages")
            
            userMessageRef.getDocuments { (querySnapshot, error) in
                if error == nil {
                    if let queryDocumentSnapshot = querySnapshot?.documents {
                        //self.count3 = 0
                        self.unseenMessageCount = 0
                        
                        for data in queryDocumentSnapshot {
                            //let key = data.documentID
                            
                            let userMessageDict = data.data()
                            
                            if let seen = userMessageDict["seen"] as? Bool {
                                if !seen {
                                    self.unseenMessageCount += 1
                                }
                            }
                        }
                        
                        if self.unseenMessageCount == 0 {
                            // Do nothing
                        } else {
                            label.text = "\(self.unseenMessageCount)"
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
    func countUnreadNotifications(label: UILabel) {
        if currentUser != nil {
            let dBase = Firestore.firestore()
            
            let notificationConnectionRequestsRef = dBase.collection("notifications").document(currentUser!).collection("connectionRequests")
            
            notificationConnectionRequestsRef.getDocuments { (querySnapshot, error) in
                if error == nil {
                    if let queryDocumentSnapshot = querySnapshot?.documents {
                        //self.count4 = 0
                        self.unseenAlertCount = 0
                        
                        for data in queryDocumentSnapshot {
                            //let key = data.documentID
                            
                            let connectionRequestDict = data.data()
                            
                            if let seen = connectionRequestDict["dealtWith"] as? Bool {
                                if !seen {
                                    self.unseenAlertCount += 1
                                }
                            }
                        }
                        
                        if self.unseenAlertCount == 0 {
                            // Do nothing
                        } else {
                            label.text = "\(self.unseenAlertCount)"
                        }
                    }
                }
            }
        }
    }
}
