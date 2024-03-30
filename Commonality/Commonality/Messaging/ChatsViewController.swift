//
//  ChatsViewController.swift
//  Spreebie
//
//  Created by Thabo David Klass on 06/07/2017.
//  Copyright © 2017 Spreebie, Inc. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseFirestore

/// Thet Chats view controller - the messages list
class ChatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    /// The table view
    @IBOutlet weak var tableView: UITableView!
    
    /// The message detail array
    var messageDetail = [MessageDetail]()
    
    /// The sorted message detail array
    var sortedMessageDetail = [MessageDetail]()
    
    /// The message detail - presumably to assign this to the selected index of the 
    /// messade detail array
    var detail: MessageDetail!
    
    /// The current user's Firebase UID
    var currentUser = KeychainWrapper.standard.string(forKey: ApplicationConstants.commonalityUserIDKey)
    
    /// The recipient
    var recipient: String!
    
    /// The messageID
    var messageID: String!
    
    /// The selected cell - the message detail cell
    var selectedCell: MessageDetailCell? =  MessageDetailCell()
    
    /// This is a boolean that tells whether the user has been on the
    /// MessagesViewController
    var didMoveForward = false
    
    /// The fourth loop count
    var count4: Int = 0
    
    /// The unseen message count
    var unseenAlertCount: Int = 0
    
    /// Has the popup been shown
    var popupShown = false
    
    /// Is this the first load
    var isFirstLoad = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        /// Set the delegates and data source
        tableView.delegate = self
        tableView.dataSource = self
        
        /// Open a constant connnect to the Spreebie Firebase dBase - connect to
        /// current user's messages node
        
        if currentUser != nil {
            loadData()
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedMessageDetail.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        /// Get the message detail
        let messageDet = sortedMessageDetail[indexPath.row]
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell") as? MessageDetailCell {
            /// Configure the message detail based on the message detail
            cell.recipientImageActivityIndicatorView.isHidden = false
            
            cell.cofigureCell(messageDetail: messageDet)
            
            /// If the message has not been seen
            if !messageDet.seen {
                /// Make the labels bold
                cell.recipientName.font = UIFont(name: "Avenir", size: 18) //UIFont.boldSystemFont(ofSize: CGFloat(18))
                cell.chatPreview.font = UIFont(name: "Avenir", size: 17) //UIFont.boldSystemFont(ofSize: CGFloat(17))
                cell.backgroundColor = UIColor(red: 232.0/255.0, green: 248.0/255.0, blue: 246.0/255.0, alpha: 1.0)
            } else {
                cell.backgroundColor = UIColor.white
            }
            
            return cell
        } else {
            return MessageDetailCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /// Get the selected recipient
        recipient = sortedMessageDetail[indexPath.row].recipient
        
        /// Get the selected message ID
        messageID = sortedMessageDetail[indexPath.row].messageKey
        
        /// Get the selected cell
        selectedCell = tableView.cellForRow(at: indexPath) as? MessageDetailCell
        
        /// Disable the boldness that may exist if a message has not been read
        selectedCell?.chatPreview.font = UIFont(name: "Avenir", size: 15)//UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)
        selectedCell?.recipientName.font = UIFont(name: "Avenir", size: 17)//UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.medium)
        
        /// Close the open connection
        //Database.database().reference().child("user").child(currentUser!).child("messages").removeAllObservers()
        
        /// Open the message
        didMoveForward = true
        performSegue(withIdentifier: "OpenMessageFromChats", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        /// Switch off the activity indicator
        if indexPath.row == tableView.indexPathsForVisibleRows?.last?.row {
            //UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationViewController = segue.destination as? MessagesViewController {
            destinationViewController.recipient = recipient
            
            destinationViewController.messageID = messageID
            
            if selectedCell != nil {
                if selectedCell!.recipientName.text != nil {
                    destinationViewController.recipientName = selectedCell!.recipientName.text!
                }
            }
        }
        
        if (segue.identifier == "OpenPopupFromChats") {
            weak var spvc = segue.destination as? StandardPopupViewController
            
            spvc!.selectedTabIndex = 2
            spvc!.informativeText = "Initiate chats with other users by tapping the chat button on their profiles."
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        /// Keep Commonality on
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Clear any existing badges
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        if let tabItems = self.tabBarController?.tabBar.items as NSArray! {
            // In this case we want to modify the badge number of the third tab:
            let tabItem = tabItems[2] as! UITabBarItem
            tabItem.badgeValue = nil
        }
        
        /// Set the home page segue thing to false
        ApplicationConstants.hasASeguedHappenedInTheHomePage = false
        
        // In case the page has been opened before
        currentUser = KeychainWrapper.standard.string(forKey: ApplicationConstants.commonalityUserIDKey)
        
        /// If the current user is not nil...
        if currentUser != nil {
            // Count the unread alerts
            countUnreadNotifications()
            
            loadData()
            
            self.didMoveForward = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        /// Close the connection when leaving this view controller
        if currentUser != nil {
            //Database.database().reference().child("user").child(currentUser!).child("messages").removeAllObservers()
        }
    }
    
    func getMyChats() {
        
    }
    
    @IBAction func refreshBarButtonItemTapped(_ sender: Any) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        self.messageDetail.removeAll()
        self.sortedMessageDetail.removeAll()
        
        self.tableView.reloadData()
        
        /// Open a constant connnect to the Spreebie Firebase dBase - connect to
        /// current user's messages node
        
        if currentUser != nil {
            loadData()
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
                            //let key = data.documentID
                            
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
     Load the message data.
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func loadData() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let dBase = Firestore.firestore()
        
        dBase.collection("users").document(currentUser!).collection("messages").addSnapshotListener { (querySnapshot, error) in
            if error == nil {
                if let queryDocumentSnapshot = querySnapshot?.documents {
                    /// Clear the message detail array
                    self.messageDetail.removeAll()
                    self.sortedMessageDetail.removeAll()
                    
                    for data in queryDocumentSnapshot {
                        let key = data.documentID
                        
                        let messageDict = data.data()
                        
                        /// Get the message details and store in it in the info
                        let info = MessageDetail(messageKey: key, messageData: messageDict as Dictionary<String, AnyObject>)
                        /// Store this in the message detail array
                        self.messageDetail.append(info)
                    }
                    
                    /// If the message detail array requires sorting based on time
                    if self.messageDetail.count > 1 {
                        self.sortedMessageDetail = self.messageDetail.sorted(by: { $0.timeStamp > $1.timeStamp })
                    } else {
                        self.sortedMessageDetail = self.messageDetail
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                }
                
                /// Reload the table view - the data source ins the message detail
                /*if self.isFirstLoad {
                    self.animateTable()
                } else {*/
                    self.tableView.reloadData()
                //}
                
                if self.messageDetail.count == 0 {
                    if !self.popupShown {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                            self.performSegue(withIdentifier: "OpenPopupFromChats", sender: nil)
                        })
                        
                        self.popupShown = true
                    }
                }
                
                self.isFirstLoad = false
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
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
        self.tableView.reloadData()
        
        let cells = self.tableView.visibleCells
        let tableHeight: CGFloat = self.tableView.bounds.size.height
        
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
