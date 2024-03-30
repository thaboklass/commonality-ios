//
//  NotificationsTableViewController.swift
//  Commonality
//
//  Created by Thabo David Klass & Mohau Mpoti on 31/3/18.
//  Copyright © 2018 Spreebie, Inc. All rights reserved.
//

import UIKit
import FirebaseFirestore

// The 'Notifications' class
class NotificationsTableViewController: UITableViewController {
    
    @IBOutlet var notificationsTableView: UITableView!
    
    /// The current user
    var currentUser: String? = KeychainWrapper.standard.string(forKey: ApplicationConstants.commonalityUserIDKey)
    
    /// The loop count
    var count: Int = 0
    
    /// The third loop count
    var count3: Int = 0
    
    /// The unseen message count
    var unseenMessageCount: Int = 0
    
    /// The array of sorted past trips
    var notifications = [CommonalityNotification]()
    
    /// The array of sorted upcoming trips
    var sortedNotifications = [CommonalityNotification]()
    
    /// The selected alert text
    var selectedNotificationText: String?
    
    // The selected alert
    var selectedNotification: CommonalityNotification? = nil
    
    /// The title text
    var titleText: String?
    
    /// This is if the local alert is opened
    var localOpen = false
    
    // The list of connections
    var connections = [String]()
    
    var selectedUser: String? = nil
    
    /// Has the popup been shown
    var popupShown = false
    
    /// Has the vertical animation run
    var verticalAnimationsHasRun = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Get alerts if the current user is logged in
        if currentUser != nil {
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        /// Keep Commonality on
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Clear any existing badges
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        if let tabItems = self.tabBarController?.tabBar.items as NSArray! {
            // In this case we want to modify the badge number of the third tab:
            let tabItem = tabItems[1] as! UITabBarItem
            tabItem.badgeValue = nil
        }
        
        /// Set the home page segue thing to false
        ApplicationConstants.hasASeguedHappenedInTheHomePage = false
        
        // In case the page has been opened before
        currentUser = KeychainWrapper.standard.string(forKey: ApplicationConstants.commonalityUserIDKey)
        
        /// If the current user is not nil...
        if currentUser != nil {
            notifications.removeAll()
            sortedNotifications.removeAll()
            notificationsTableView.reloadData()
            
            loadRequests()
            getConnections()
        }
        
        // Count the unread messages
        countUnreadMessages()
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return sortedNotifications.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationsCell", for: indexPath) as! NotificationsTableViewCell
        
        /// Set the button defaults
        cell.noButton.isEnabled = true
        cell.noButton.isHidden = false
        
        cell.yesButton.isEnabled = true
        cell.yesButton.isHidden = false
        
        cell.notificationSenderActivityIndicatorView.isHidden = false
        
        let notification = sortedNotifications[indexPath.row]
        
        if notification.actorName != nil {
            cell.nameButton.setTitle(notification.actorName!, for: .normal)
        }
        
        if notification.notificationType != nil {
            if notification.notificationType! == "connectionRequest" {
                cell.notificationTextLabel.text = "...would like to connect with you. Do you agree?"
                
                // This is implements the no button from the table cell
                cell.onNoButtonTapped = {
                    if notification.key != nil {
                        self.ignoreRequest(connectionRequestID: notification.key!)
                    }
                }
                
                // This is implements the yes button from the table cell
                cell.onYesButtonTapped = {
                    if notification.key != nil && notification.actor != nil {
                        self.connect(requestingUser: notification.actor!, connectionRequestID: notification.key!)
                    }
                }
            }
            
            if notification.notificationType! == "nudge" {
                cell.notificationTextLabel.text = "...just nudged you. How about responding?"
                
                cell.noButton.isEnabled = false
                cell.noButton.isHidden = true
                
                cell.yesButton.isEnabled = false
                cell.yesButton.isHidden = true
            }
        }
        
        if notification.actor != nil {
            cell.setProfilePicture(user: notification.actor!)
            cell.onNameButtonTapped = {
                print("\(notification.actorName!) tapped.")
                
                if notification.actor != nil {
                    self.selectedUser = notification.actor
                    
                    self.performSegue(withIdentifier: "OpenProfileFromNotifications", sender: nil)
                }
            }
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "OpenProfileFromNotifications") {
            weak var mupvc = segue.destination as? CommonalityUserProfileViewController
            
            mupvc?.pickedUser = selectedUser
            mupvc?.currentUserConnections = self.connections
        }
        
        if (segue.identifier == "OpenPopupFromNotifications") {
            weak var spvc = segue.destination as? StandardPopupViewController
            
            spvc!.selectedTabIndex = 1
            spvc!.informativeText = "Make connection requests or nudge other people as a way to initiate interactions."
        }
    }
    
    // Converts time stamp to date
    func convertTimeStampToDate(timeStamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timeStamp))
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.medium //Set time style
        dateFormatter.dateStyle = DateFormatter.Style.medium //Set date style
        let localDate = dateFormatter.string(from: date)
        
        return localDate
    }
    
    func emptyData() {
        
    }
    
    @IBAction func refreshBarButtonItemTapped(_ sender: Any) {
        emptyData()
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
    
    // Load all the requests
    func loadRequests() {
        if currentUser != nil {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            self.count = 0
            notifications.removeAll()
            
            // Get firestore dBase
            let dBase = Firestore.firestore()
            
            let currentUserRequestsRef = dBase.collection("notifications").document(currentUser!).collection("connectionRequests")
            
            currentUserRequestsRef.getDocuments { (querySnapshot, error) in
                if error == nil {
                    if let snapshot = querySnapshot {
                        let documents = snapshot.documents
                        
                        for document in documents {
                            let requestDict = document.data()
                            let key = document.documentID
                            
                            if let dealtWith = requestDict["dealtWith"] as? Bool {
                                if !dealtWith {
                                    /// Create a notification from the dictionary
                                    let notification = CommonalityNotification(key: key, userData: requestDict as Dictionary<String, AnyObject>)
                                    self.notifications.append(notification)
                                }
                            }
                        }
                        
                        if self.notifications.count > 1 {
                            self.sortedNotifications = self.notifications.sorted(by: { $0.creationAt! > $1.creationAt! })
                        } else {
                            self.sortedNotifications = self.notifications
                        }
                        
                        self.animateTable()

                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        
                        /// Load nudges
                        self.loadNudges()
                    }
                }
            }
        }
    }
    
    
    /**
     This ignores a connection request
     
     - Parameters:
     - connectionRequestID: The reguest ID
     
     - Returns: void.
     */
    func ignoreRequest(connectionRequestID: String) {
        if currentUser != nil {
            let requestData = [
                "dealtWith": true
                ] as [String : Any]
            
            let dBase = Firestore.firestore()
            let connectionRequestRef = dBase.collection("notifications").document(currentUser!).collection("connectionRequests").document(connectionRequestID)
            
            connectionRequestRef.updateData(requestData) { err in
                if let err = err {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    
                    self.displayCommonalityGenericAlert("Error!", userMessage: "There was an error saving your data. Please try again.")
                } else {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false

                    self.animateTable()
                    
                    self.displayCommonalityGenericAlert("Request Ignored", userMessage: "The connection request was ignored.")
                    
                }
            }
        }
    }
    
    
    /**
     Connect the current user with a requester.
     
     - Parameters:
     - requestingUser: The requester user ID
     - connectionRequestID: The connection request user ID
     
     - Returns: void.
     */
    func connect(requestingUser: String, connectionRequestID: String) {
        if currentUser != nil {
            /// Get the current user's connections and then append the new one
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            /// The currentUserConnections
            var currentUserConnections = [String]()
            
            // Get firestore dBase
            let dBase = Firestore.firestore()
            
            let connectionRef = dBase.collection("connections").document(currentUser!)
            
            connectionRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    if let connectionDict = document.data() {
                        /// Check for nil again
                        if let cnxs = connectionDict["connectionList"] as? [String] {
                            // Assign the connections if the exist
                            currentUserConnections = cnxs
                            
                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        }
                    }
                } else {
                    print("Error: \(String(describing: error?.localizedDescription))")
                }
                
                currentUserConnections.append(requestingUser)
                
                let connectionData: [String: Any] = [
                    "connectionList": currentUserConnections
                ]
                
                dBase.collection("connections").document(self.currentUser!).setData(connectionData)
                
                /// Make sure the request is set as dealt with
                let requestData = [
                    "dealtWith": true
                    ] as [String : Any]
                
                let dBase = Firestore.firestore()
                let connectionRequestRef = dBase.collection("notifications").document(self.currentUser!).collection("connectionRequests").document(connectionRequestID)
                
                connectionRequestRef.updateData(requestData) { err in
                    if let err = err {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        
                        self.displayCommonalityGenericAlert("Error!", userMessage: "There was an error saving your data. Please try again.")
                    } else {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        self.loadRequests()
                        
                        self.displayCommonalityGenericAlert("Request accepted", userMessage: "The connection request was accepted and the user was added to your connection list.")
                        
                    }
                }
            }
            
            /// Get the requester's connections and then append the current user
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            /// The currentUserConnections
            var requesterConnections = [String]()
            
            let requesterConnectionRef = dBase.collection("connections").document(requestingUser)
            
            requesterConnectionRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    if let connectionDict = document.data() {
                        /// Check for nil again
                        if let cnxs = connectionDict["connectionList"] as? [String] {
                            // Assign the connections if the exist
                            requesterConnections = cnxs
                            
                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        }
                    }
                } else {
                    print("Error: \(String(describing: error?.localizedDescription))")
                }
                
                requesterConnections.append(self.currentUser!)
                
                let requesterConnectionData: [String: Any] = [
                    "connectionList": requesterConnections
                ]
                
                dBase.collection("connections").document(requestingUser).setData(requesterConnectionData)
            }
        }
    }
    
    // Get the conne
    func getConnections() {
        /// Check for nil
        if currentUser != nil {
            connections.removeAll()
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            // Get firestore dBase
            let dBase = Firestore.firestore()
            
            let connectionRef = dBase.collection("connections").document(currentUser!)
            
            connectionRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    if let connectionDict = document.data() {
                        /// Check for nil again
                        if let cnxs = connectionDict["connectionList"] as? [String] {
                            // Assign the connections if the exist
                            self.connections = cnxs
                            
                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        }
                    }
                } else {
                    print("Error: \(String(describing: error?.localizedDescription))")
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
    
    // Load the nudges
    func loadNudges() {
        if currentUser != nil {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            // Get firestore dBase
            let dBase = Firestore.firestore()
            
            let currentUserRequestsRef = dBase.collection("notifications").document(currentUser!).collection("nudges")
            
            currentUserRequestsRef.getDocuments { (querySnapshot, error) in
                if error == nil {
                    if let snapshot = querySnapshot {
                        let documents = snapshot.documents
                        
                        for document in documents {
                            let requestDict = document.data()
                            let key = document.documentID
                            
                            if let dealtWith = requestDict["dealtWith"] as? Bool {
                                if !dealtWith {
                                    /// Create a notification from the dictionary
                                    let notification = CommonalityNotification(key: key, userData: requestDict as Dictionary<String, AnyObject>)
                                    self.notifications.append(notification)
                                }
                            }
                        }
                        
                        if self.notifications.count > 1 {
                            self.sortedNotifications = self.notifications.sorted(by: { $0.creationAt! > $1.creationAt! })
                        } else {
                            self.sortedNotifications = self.notifications
                        }

                        self.animateTable()
                    }
                    
                    if self.notifications.count == 0 {
                        if !self.popupShown {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                                self.performSegue(withIdentifier: "OpenPopupFromNotifications", sender: nil)
                            })
                            
                            self.popupShown = true
                        }
                    }
                    
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
            }
        }
    }
    
    /**
     Animates the table view.
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func animateTable() {
        self.notificationsTableView.reloadData()
            
        let cells = self.notificationsTableView.visibleCells
        let tableHeight: CGFloat = self.notificationsTableView.bounds.size.height
        
        for i in cells {
            let cell: UITableViewCell = i as UITableViewCell
            cell.transform = CGAffineTransform(translationX: 0, y: tableHeight)
        }
        
        var index = 0
        
        for m in cells {
            let cell: UITableViewCell = m as UITableViewCell
            UIView.animate(withDuration: 0.5, delay: 0.05 * Double(index), usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: {
                cell.transform = CGAffineTransform.identity
            }, completion: nil)
            index += 1
        }
    }
}
