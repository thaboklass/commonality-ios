//
//  MessagesViewController.swift
//  Spreebie
//
//  Created by Thabo David Klass on 30/07/2017.
//  Copyright © 2017 Spreebie, Inc. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseFirestore
import AWSSNS

/// Thet Messages view controller - the messages list
class MessagesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    /// The view controller's main view
    @IBOutlet var mainView: UIView!
    
    /// The send button
    @IBOutlet weak var sendButton: UIButton!
    
    /// The message field
    @IBOutlet weak var messageField: UITextField!
    
    /// The view controller's table view
    @IBOutlet weak var tableView: UITableView!
    
    /// The current message's ID - that is, the message ID of the thread
    var messageID: String!
    
    /// The messages array
    var messages = [Message]()
    
    /// The sorted messages array
    var sortedMessages = [Message]()
    
    /// The current message
    var message: Message!
    
    /// The current user's Firebase UID
    var currentUser = KeychainWrapper.standard.string(forKey: ApplicationConstants.commonalityUserIDKey)
    
    /// The recipient - the recipient of the thread
    var recipient: String!
    
    /// Has the latest message been seen?
    var seen = false
    
    /// The recipient name
    var recipientName = "User"
    
    /// This store boolan detailing wherether a push notification
    var notificationSent = false
    
    /// The reference to the user typing
    var userIsTypingRef: DatabaseReference!
    
    /// The local typing boolean
    private var localTyping = false
    
    /// Computed property updates localTyping and userIsTyping each time
    /// it is changed
    var isTyping: Bool {
        get {
            return localTyping
        }
        set {
            localTyping = newValue
            if userIsTypingRef != nil {
                userIsTypingRef.setValue(newValue)
            }
        }
    }
    
    // The query to the user typing
    var usersTypingQuery: DatabaseQuery!
    
    /// The text field timer
    var textFieldTimer: Timer!
    
    var messagePushSent = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        /// Set the recipeint name in the title
        self.navigationItem.title = recipientName
        
        /// Create a rounder border for the button
        let sendButtonLayer: CALayer?  = sendButton.layer
        sendButtonLayer!.cornerRadius = 4
        sendButtonLayer!.masksToBounds = true
        
        /// The table view delegate
        tableView.delegate = self
        
        /// The table datasource
        tableView.dataSource = self
        
        /// I forgot what this is for
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.estimatedRowHeight = 300
        
        /// Remove the table separator from the table
        tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        
        /// The text field delegate
        messageField.delegate = self
        
        if messageID != "" && messageID != nil {
            if recipient != nil {
                startMessageListener()
                
                observeTyping()
            } else {
                sendButton.isEnabled = false
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                displayMyAlertMessage("Data error", userMessage: "There was an error in the data and as such the messaging has been disabled. Please move back to the origin of the spreebie or this messager re-open it.")
            }
        } else {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
        
        /// Keyboard mitigation
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        
        view.addGestureRecognizer(tap)
        
        /// Move to the bottom of the table view - doesn't seem to work for some reason
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
            self.moveToBottom()
        }
        
        /// Add a change listener to text field
        messageField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        // If the text is not empty, the user is typing
        isTyping = messageField.text != ""
        updateTypists()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if textFieldTimer != nil {
            textFieldTimer.invalidate()
        }
        textFieldTimer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(getHintsFromTextField),
            userInfo: ["textField": textField],
            repeats: false)
        return true
    }
    
    @objc func getHintsFromTextField(textField: UITextField) {
        isTyping = false
        updateTypists()
    }
    
    /// Keyboard mitigation
    @objc func keyboardWillShow(notify: NSNotification) {
        if let keyboardSize = (notify.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notify: NSNotification) {
        if let keyboardSize = (notify.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0 {
                self.view.frame.origin.y += keyboardSize.height
            }
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = sortedMessages[indexPath.row]
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "Message") as? MessagesCell {
            if currentUser != nil {
                if message.sender == recipient || message.sender == currentUser! {
                    cell.configCell(message: message)
                }
            }
            
            return cell
        } else {
            return MessagesCell()
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == tableView.indexPathsForVisibleRows?.last?.row {
            /// Switch off the network activity indicator
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    func startMessageListener() {
        let dBase = Firestore.firestore()
        
        dBase.collection("messages").document(messageID).collection("childMessages").addSnapshotListener { (querySnapshot, error) in
            if error == nil {
                self.loadData()
            }
        }
    }
    
    /**
     Loads the message from linked to the message ID.
     
     - Parameters:
     - none
     
     - Returns: nothing.
     */
    func loadData() {
        let dBase = Firestore.firestore()
        
        let messageRef = dBase.collection("messages").document(messageID).collection("childMessages")
        
        messageRef.getDocuments { (querySnapshot, error) in
            if error == nil {
                if let queryDocumentSnapshot = querySnapshot?.documents {
                    self.messages.removeAll()
                    self.sortedMessages.removeAll()
                    
                    for data in queryDocumentSnapshot {
                        let key = data.documentID
                        
                        let messageDict = data.data()
                        
                        let post = Message(messageKey: key, postData: messageDict as Dictionary<String, AnyObject>)
                        self.messages.append(post)
                    }
                    
                    if self.messages.count > 1 {
                        self.sortedMessages = self.messages.sorted(by: { $0.timeStamp < $1.timeStamp })
                    } else {
                        self.sortedMessages = self.messages
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                }
                
                /// Load the data
                self.tableView.reloadData()
                /// Set the last message as read
                self.setMessageAsRead()
                
                /// Scroll to the last message after the loading is done
                self.scrollToBottom(animated: true)
            }
        }
    }
    
    /**
     Scroll the table view to the last cell.
     
     - Parameters:
     - none
     
     - Returns: nothing.
     */
    func moveToBottom() {
        if messages.count > 0 {
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
            
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
    }
    
    @IBAction func sendPressed(_ sender: Any) {
        /// Keyboard mitigation
        dismissKeyboard()
        
        /// Create the unix time stamp
        let currentDate = Date()
        let timeStamp = Int(currentDate.timeIntervalSince1970)
        
        /// If there is no  message ID - in this context, this is when the users have never communicated before.
        if (messageField.text != nil && messageField.text != "") {
            
            if messageID == nil {
                // Key combination
                let keyCombo: Dictionary<String, AnyObject> = [
                    "keyCombo": currentUser! + recipient as AnyObject
                ]
                
                /// Create the message to be stored under the message ID
                let post: Dictionary<String, AnyObject> = [
                    "message": messageField.text as AnyObject,
                    "sender": recipient as AnyObject,
                    "time_stamp": timeStamp as AnyObject
                ]
                
                /// Create the message for the recipient - this is the only message that will be stored linked
                /// to this user about the msssage ID thread
                let message: Dictionary<String, AnyObject> = [
                    "lastmessage": messageField.text as AnyObject,
                    "recipient": recipient as AnyObject,
                    "seen": true as AnyObject,
                    "time_stamp": timeStamp as AnyObject
                ]
                
                /// Create the message for the recipient - this is the only message that will be stored linked
                /// to this user about the msssage ID thread
                let recipientMessage: Dictionary<String, AnyObject> = [
                    "lastmessage": messageField.text as AnyObject,
                    "recipient": currentUser as AnyObject,
                    "seen": seen as AnyObject,
                    "time_stamp": timeStamp as AnyObject
                ]
                
                /// The message ID now exists
                let dBase = Firestore.firestore()
                
                // Add a new document with a generated id.
                var messageRef: DocumentReference? = nil
                messageRef = dBase.collection("messages").addDocument(data: keyCombo) { err in
                    if let err = err {
                        print("Error adding document: \(err)")
                    } else {
                        print("Document added with ID: \(messageRef!.documentID)")
                        self.messageID = messageRef!.documentID
                        
                        messageRef!.collection("childMessages").addDocument(data: post)
                        
                        let recipientRef = dBase.collection("users").document(self.recipient)
                        recipientRef.collection("messages").document(self.messageID).setData(recipientMessage)
                        
                        let senderRef = dBase.collection("users").document(self.currentUser!)
                        senderRef.collection("messages").document(self.messageID).setData(message)
                        
                        /// Re-load the table data
                        self.loadData()
                        self.startMessageListener()
                        self.observeTyping()
                        
                        self.sendMessagePushNotifications()
                    }
                }
                
                //sendMessagePushNotifications()
            } else if messageID != "" {
                let keyCombo: Dictionary<String, AnyObject> = [
                    "keyCombo": currentUser! + recipient as AnyObject
                ]
                
                /// Create the message to be stored under the message ID
                let post: Dictionary<String, AnyObject> = [
                    "message": messageField.text as AnyObject,
                    "sender": recipient as AnyObject,
                    "time_stamp": timeStamp as AnyObject
                ]
                
                /// Create the message for the recipient - this is the only message that will be stored linked
                /// to this user about the msssage ID thread
                let message: Dictionary<String, AnyObject> = [
                    "lastmessage": messageField.text as AnyObject,
                    "recipient": recipient as AnyObject,
                    "seen": true as AnyObject,
                    "time_stamp": timeStamp as AnyObject
                ]
                
                /// Create the message for the recipient - this is the only message that will be stored linked
                /// to this user about the msssage ID thread
                let recipientMessage: Dictionary<String, AnyObject> = [
                    "lastmessage": messageField.text as AnyObject,
                    "recipient": currentUser as AnyObject,
                    "seen": seen as AnyObject,
                    "time_stamp": timeStamp as AnyObject
                ]
                
                let dBase = Firestore.firestore()
                
                // Add a new document with a generated id.
                var messageRef: DocumentReference? = nil
                messageRef = dBase.collection("messages").document(self.messageID).collection("childMessages").addDocument(data: post) { err in
                    if let err = err {
                        print("Error adding document: \(err)")
                    } else {
                        /// Link the message to this user
                        let recipientRef = dBase.collection("users").document(self.recipient)
                        recipientRef.collection("messages").document(self.messageID).setData(recipientMessage)
                        
                        let senderRef = dBase.collection("users").document(self.currentUser!)
                        senderRef.collection("messages").document(self.messageID).setData(message)
                        
                        self.sendMessagePushNotifications()
                    }
                }
            }
            
            /// Clear the message field
            messageField.text = ""
        }
        
        isTyping = false
        updateTypists()
        
        /// Move to the bottom
        moveToBottom()
    }
    
    /**
     Set a message as read after it has appeared on the table.
     
     - Parameters:
     - none
     
     - Returns: nothing.
     */
    func setMessageAsRead() {
        if self.messageID != nil {
            /// The payload
            let userData = [
                "seen": true
                ] as [String : Any]
            
            let dBase = Firestore.firestore()
            let userRef = dBase.collection("users").document(self.currentUser!).collection("messages").document(self.messageID)
            
            userRef.updateData(userData)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        /// Close the connection
        if messageID != nil {
            //Database.database().reference().child("messages").child(messageID).removeAllObservers()
            //Database.database().reference().child("messages").child(messageID).child("childMessages").removeAllObservers()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Hide this ViewController's navigation bar
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    private func observeTyping() {
        if messageID != "" && messageID != nil {
            let dBase = Firestore.firestore()
            
            dBase.collection("messages").document(messageID).collection("typists").document(recipient).addSnapshotListener { (querySnapshot, error) in
                if error == nil {
                    if let typistsExists = querySnapshot?.exists {
                        if typistsExists {
                            self.navigationItem.title = "typing..."
                        } else {
                            self.navigationItem.title = self.recipientName
                        }
                    } else {
                        self.navigationItem.title = self.recipientName
                    }
                }
            }
        }
    }
    
    func updateTypists() {
        if currentUser != nil {
            if messageID != nil {
                if isTyping {
                    let typistData = [
                        "isTyping": true
                    ] as [String : Any]
                    
                    let dBase = Firestore.firestore()
                    dBase.collection("messages").document(messageID).collection("typists").document(currentUser!).setData(typistData)
                } else {
                    let dBase = Firestore.firestore()
                    dBase.collection("messages").document(messageID).collection("typists").document(currentUser!).delete()
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //observeTyping()
    }
    
    func scrollToBottom(animated: Bool) {
        /// Scroll to the last message after the loading is done
        if self.tableView.numberOfRows(inSection: 0) > 0 {
            let lastRow = self.tableView.numberOfRows(inSection: 0) - 1
            let lastIndexPath = IndexPath(row: lastRow, section: 0)
            self.tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: true)
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
    
    
    /**
     Sends a push notification for the initial message send.
     
     - Parameters:
     - title: The title text
     - userMessage: The message text
     
     - Returns: void.
     */
    func sendMessagePushNotifications() {
        /// Check for nil
        if currentUser != nil {
            /// Get the user reference
            let dBase = Firestore.firestore()
            let messageRef = dBase.collection("users").document(recipient)
            
            messageRef.getDocument { (querySnapshot, error) in
                if let userDict = querySnapshot?.data() {
                    if let deviceArn = userDict["deviceArn"] as? String, let deviceTokenSNS = userDict["deviceTokenSNS"] as? String {
                        
                        if (!self.messagePushSent) {
                            
                            /// Push notification meant for the spreebie uploader
                            let sns = AWSSNS.default()
                            let request = AWSSNSPublishInput()
                            
                            request?.messageStructure = "json"
                            
                            /// The payload
                            let dict = ["default": "You have received a new direct message.", ApplicationConstants.commonalityAPNSType: "{\"aps\":{\"alert\": {\"title\":\"New direct message\",\"body\":\"You have received a new direct message.\"},\"sound\":\"default\",\"badge\":1} }"]
                            
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
                                            self.messagePushSent = true
                                        }
                                        return nil
                                }
                            } catch {
                                
                            }
                        }
                        
                        /// Enable the interface
                        //self.enableInterface()
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                }
            }
        }
    }
}
