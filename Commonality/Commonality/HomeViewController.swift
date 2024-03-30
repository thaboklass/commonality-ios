//
//  HomeViewController.swift
//  Commonality
//
//  Created by Thabo David Klass & Mohau Mpoti on 22/3/18.
//  Copyright © 2018 Spreebie, Inc. All rights reserved.
//

import UIKit
import FirebaseFirestore
import AWSMobileHubContentManager
import AWSAuthCore
import MessageUI
import Contacts
import ContactsUI
import AWSSNS

/// The Home View Controller class - this is the app's entry point
class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, TagListViewDelegate, CNContactPickerDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var commonalityTableView: UITableView!
    
    @IBOutlet weak var joinTripButton: UIButton!
    @IBOutlet weak var createTripButton: UIButton!
    @IBOutlet weak var buddiesButton: UIButton!
    @IBOutlet weak var editProfileButton: UIButton!
    
    @IBOutlet weak var loginBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var borderView: UIView!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var schoolLabel: UILabel!
    @IBOutlet weak var roleLabel: UILabel!
    
    
    // MARK: - Instance Variables
    
    /// The current user
    var currentUser: String? = KeychainWrapper.standard.string(forKey: ApplicationConstants.commonalityUserIDKey)
    
    /// The current user name
    var currentUserName: String? = nil
    
    /// The loop count
    var count: Int = 0
    
    /// The second loop count
    var count2: Int = 0
    
    /// The third loop count
    var count3: Int = 0
    
    /// The unseen message count
    var unseenMessageCount: Int = 0
    
    /// The fourth loop count
    var count4: Int = 0
    
    /// The fourth loop count
    var count5: Int = 0
    
    /// The unseen message count
    var unseenAlertCount: Int = 0
    
    /// The second loop count
    var genericCount: Int = 0
    
    /// The max number of comments in the arrays
    var countMax: Int = 1000
    
    /// The selected profile pic image that will be passed to the
    // TripDetailsViewController
    var selectedProfilePicture: UIImage? = nil
    
    /// The empty trip participants array that will be passed to the
    /// trip details view controller after the click
    var tripParticipants = [(userID: String, participantFullname: String, grade: String?, school: String?, participantProfilePicURL: String?)]()
    
    /// Is this the first load of the view controller?
    var isFirstLoad = true
    
    /// User just recently opened the login page
    var userComesFromLogin = false
    
    /// The leader ID when not logged int
    var genericTripLeader: String? = nil
    
    /// The current user's school
    var currentUserSchool: String? = nil
    
    /// The current user's role
    var currentUserRole: String? = nil
    
    /// The current user's role details
    var currentUserRoleDetails: String? = nil

    /// The refresh control - pull down refresh
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: UIControlEvents.valueChanged)
        
        return refreshControl
    }()
    
    /// The user profile picture name
    var profilePictureFileName = ApplicationConstants.dbEmptyValue
    
    // Connected devices
    var connectedDevices = [String]()
    
    var commonalityService: CommonalityServiceManager? = nil
    
    /// The array of people
    var people = [User]()
    
    // S3 folder variables. These are used to navigate through
    // the remote file system
    var manager: AWSUserFileManager!
    var contents: [AWSContent]?
    var marker: String?
    var prefix: String!
    
    // People/Folder/Friends button booleans
    var peopleSelected = true
    var foldersSelected = false
    var buddiesSelected = false
    
    // This holds folder strings
    var folders = [String]()
    // This holds an array of users
    var peopleFolders = [User]()
    
    // Selected folder owner details
    var selectedFolderOwner: String? = nil
    var selectedFolderOwnerFirstName: String? = nil
    
    // The list of connections
    var connections = [String]()
    
    /// The type of message
    var messageType: String?
    
    /// The email or mobile number...
    var contactIdentifier: String? = nil
    
    /// The recipient's contact name
    var contactName: String? = nil
    
    /// The buddies
    var buddies = [User]()
    
    /// The matching users
    var matches = [User]()
    
    /// Has the popup been shown
    var popupShown = false
    
    /// The page transition
    let transition = CircularTransition()
    
    /// The message ID
    var messageID: String!
    
    /// The selected chat recipient
    var selectedChatRecipient: String? = nil
    
    /// The selected chat recipient name
    var selectedChatRecipientName: String? = nil
    
    /// The tooltip restrictors
    var peersTooltipHasBeenShow = false
    var foldersTooltipHasBeenShow = false
    var buddiesTooltipHasBeenShow = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Select the current ViewController as the TableView's delegate and datasource
        commonalityTableView.delegate = self
        commonalityTableView.dataSource = self
        
        /// For the transition
        self.navigationController?.delegate = self
        
        // Shows the tab bar
        if let bar = self.tabBarController?.tabBar {
            bar.isHidden = false
        }
        
        // Hide the Back Button to the Login screen
        navigationItem.setHidesBackButton(true, animated: false)
        
        let greenish = UIColor(red: 45.0/255.0, green: 182.0/255.0, blue: 174.0/255.0, alpha: 1.0)
        
        let imageLayer: CALayer?  = self.profilePictureImageView.layer
        imageLayer!.cornerRadius = self.profilePictureImageView.frame.height / 2
        imageLayer!.borderWidth = 2.0
        imageLayer!.borderColor = UIColor.white.cgColor
        imageLayer!.masksToBounds = true
        
        let borderLayer: CALayer?  = self.borderView.layer
        borderLayer!.cornerRadius = self.profilePictureImageView.frame.height / 2
        borderLayer!.borderWidth = 2.0
        borderLayer!.borderColor = greenish.cgColor
        borderLayer!.masksToBounds = true
        
        // Create rounded borders for around the 'Join Trip' and 'Create Trip' buttons
        joinTripButton.layer.cornerRadius = 12
        joinTripButton.layer.masksToBounds = true
        
        createTripButton.layer.cornerRadius = 12
        createTripButton.layer.masksToBounds = true
        
        buddiesButton.layer.cornerRadius = 12
        buddiesButton.layer.masksToBounds = true
        
        let editProfileButtonLayer: CALayer?  = editProfileButton.layer
        editProfileButtonLayer!.cornerRadius = 4
        editProfileButtonLayer!.masksToBounds = true
        
        // Do some additional formatting on the buttons
        let purplish = UIColor(red: 192.0/255.0, green: 30.0/255.0, blue: 201.0/255.0, alpha: 1.0)
        
        createTripButton.layer.backgroundColor = purplish.cgColor
        createTripButton.setTitleColor(UIColor.white, for: .normal)
        
        /// Add the refresh control to the view controller
        commonalityTableView.addSubview(self.refreshControl)
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        if currentUser == nil {
            // Disable the tabs if the user is not
            // logged in
            disableTabsButCurrentIndex(index: 0)
            
            createTripButton.isEnabled = false
            joinTripButton.isEnabled = false
            buddiesButton.isEnabled = false
            editProfileButton.isEnabled = false
            
            /// Time the opening of the onboarder
            Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.timedSegueToOnboarder), userInfo: nil, repeats: false)
        } else {
            loginBarButtonItem.isEnabled = false
            loginBarButtonItem.tintColor = UIColor.clear
            
            createTripButton.isEnabled = true
            joinTripButton.isEnabled = true
            buddiesButton.isEnabled = true
            editProfileButton.isEnabled = true
            
            commonalityService = CommonalityServiceManager()
            commonalityService!.delegate = self
            
            // Set user data
            setUserData()
            
            // Save the device token to the database
            saveCurrentDeviceToken()
            
            // Save the device ARN to the database
            saveCurrentDeviceTokenAndArn()
            
            // Create remote folder
            manager = AWSUserFileManager.defaultUserFileManager()
            createRemoteFolder()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /// Keep Commonality on
        UIApplication.shared.isIdleTimerDisabled = true
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        
        /// Set the current user after login/signup
        currentUser = KeychainWrapper.standard.string(forKey: ApplicationConstants.commonalityUserIDKey)
        
        let purplish = UIColor(red: 192.0/255.0, green: 30.0/255.0, blue: 201.0/255.0, alpha: 1.0)
        
        joinTripButton.layer.backgroundColor = purplish.cgColor
        joinTripButton.setTitleColor(UIColor.white, for: .normal)
        
        createTripButton.layer.backgroundColor = UIColor.white.cgColor
        createTripButton.setTitleColor(purplish, for: .normal)
        
        createTripButton.layer.borderWidth = 1
        createTripButton.layer.borderColor = purplish.cgColor
        
        buddiesButton.layer.backgroundColor = UIColor.white.cgColor
        buddiesButton.setTitleColor(purplish, for: .normal)
        
        buddiesButton.layer.borderWidth = 1
        buddiesButton.layer.borderColor = purplish.cgColor
        
        if currentUser == nil {
            // Disable the tabs if the user is not
            // logged in
            disableTabsButCurrentIndex(index: 0)
            self.navigationItem.leftBarButtonItem! = UIBarButtonItem(title: ApplicationConstants.commonalityLoginButtonValue, style: UIBarButtonItemStyle.plain, target: self, action: #selector(HomeViewController.loginButtonTapped(_:)))
            
            createTripButton.isEnabled = false
            joinTripButton.isEnabled = false
            buddiesButton.isEnabled = false
            editProfileButton.isEnabled = false
            
            let justLoggedOut = KeychainWrapper.standard.string(forKey: ApplicationConstants.commonalityUserJustLoggedOutValue)
            
            if justLoggedOut != nil {
                if justLoggedOut == ApplicationConstants.commonalitySmallYesValue {
                    KeychainWrapper.standard.set(ApplicationConstants.commonalitySmallNoValue, forKey: ApplicationConstants.commonalityUserJustLoggedOutValue)
                    
                    /// Time the opening of the onboarder
                    Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.timedSegueToOnboarder), userInfo: nil, repeats: false)
                }
            }
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: .UIApplicationWillResignActive, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(willBecomeActive), name: .UIApplicationWillEnterForeground, object: nil)
            
            let showPopups = KeychainWrapper.standard.string(forKey: "commonalityShowPopups")
            
            if showPopups != nil {
                if showPopups == ApplicationConstants.commonalitySmallNoValue {
                    peersTooltipHasBeenShow = true
                    foldersTooltipHasBeenShow = true
                    buddiesTooltipHasBeenShow = true
                }
            }
            
            if commonalityService == nil {
                commonalityService = CommonalityServiceManager()
                commonalityService!.delegate = self
            }
            
            // Populate the current user in both the people and
            // the folders section
            if !connectedDevices.contains(currentUser!) {
                connectedDevices.append(currentUser!)
            }
            
            // Load the people section
            if peopleSelected {
                let purplish = UIColor(red: 192.0/255.0, green: 30.0/255.0, blue: 201.0/255.0, alpha: 1.0)
                
                joinTripButton.layer.backgroundColor = purplish.cgColor
                joinTripButton.setTitleColor(UIColor.white, for: .normal)
                
                createTripButton.layer.backgroundColor = UIColor.white.cgColor
                createTripButton.setTitleColor(purplish, for: .normal)
                
                createTripButton.layer.borderWidth = 1
                createTripButton.layer.borderColor = purplish.cgColor
                
                buddiesButton.layer.backgroundColor = UIColor.white.cgColor
                buddiesButton.setTitleColor(purplish, for: .normal)
                
                buddiesButton.layer.borderWidth = 1
                buddiesButton.layer.borderColor = purplish.cgColor
                
                if !ApplicationConstants.hasASeguedHappenedInTheHomePage {
                    populatePeople()
                }
                
                if !peersTooltipHasBeenShow {
                    AMTooltipView(message: "Your 'peers' are the people around you with Commonality on their phones. To be able to 'see' and be 'seen' by your peers, make sure to be on the same wifi network or bluetooth personal area network as them.",
                                  focusView: joinTripButton, //pass view you want show tooltip over it
                        target: self)
                    
                    peersTooltipHasBeenShow = true
                }
            } else if foldersSelected {
                let purplish = UIColor(red: 192.0/255.0, green: 30.0/255.0, blue: 201.0/255.0, alpha: 1.0)
                
                createTripButton.layer.backgroundColor = purplish.cgColor
                createTripButton.setTitleColor(UIColor.white, for: .normal)
                
                joinTripButton.layer.backgroundColor = UIColor.white.cgColor
                joinTripButton.setTitleColor(purplish, for: .normal)
                
                joinTripButton.layer.borderWidth = 1
                joinTripButton.layer.borderColor = purplish.cgColor
                
                buddiesButton.layer.backgroundColor = UIColor.white.cgColor
                buddiesButton.setTitleColor(purplish, for: .normal)
                
                buddiesButton.layer.borderWidth = 1
                buddiesButton.layer.borderColor = purplish.cgColor
                
                if !ApplicationConstants.hasASeguedHappenedInTheHomePage {
                    populateFolders()
                }
            } else {
                
                let purplish = UIColor(red: 192.0/255.0, green: 30.0/255.0, blue: 201.0/255.0, alpha: 1.0)
                
                buddiesButton.layer.backgroundColor = purplish.cgColor
                buddiesButton.setTitleColor(UIColor.white, for: .normal)
                
                joinTripButton.layer.backgroundColor = UIColor.white.cgColor
                joinTripButton.setTitleColor(purplish, for: .normal)
                
                joinTripButton.layer.borderWidth = 1
                joinTripButton.layer.borderColor = purplish.cgColor
                
                createTripButton.layer.backgroundColor = UIColor.white.cgColor
                createTripButton.setTitleColor(purplish, for: .normal)
                
                createTripButton.layer.borderWidth = 1
                createTripButton.layer.borderColor = purplish.cgColor
                
                if !ApplicationConstants.hasASeguedHappenedInTheHomePage {
                    populateBuddies()
                }
            }
            
            // Enable the tabs after the user logs in
            enableAllTabs()
            
            // Count the unread messages
            countUnreadMessages()
            
            // Count the unread alerts
            countUnreadNotifications()
            
            self.navigationItem.leftBarButtonItem! = UIBarButtonItem(title: "Invite", style: UIBarButtonItemStyle.plain, target: self, action: #selector(HomeViewController.loginButtonTapped(_:)))
            
            createTripButton.isEnabled = true
            joinTripButton.isEnabled = true
            buddiesButton.isEnabled = true
            editProfileButton.isEnabled = true
            
            let justLogged = KeychainWrapper.standard.string(forKey: ApplicationConstants.commonalityUserJustLoggedInValue)
            
            if justLogged != nil {
                if justLogged == ApplicationConstants.commonalitySmallYesValue {
                    KeychainWrapper.standard.set(ApplicationConstants.commonalitySmallNoValue, forKey: ApplicationConstants.commonalityUserJustLoggedInValue)
                    
                    emptyData()
                    commonalityTableView.reloadData()
                    
                    // Set user data
                    setUserData()
                    
                    // Save the device token to the database
                    saveCurrentDeviceToken()
                    
                    // Save the device ARN to the database
                    saveCurrentDeviceTokenAndArn()
                }
            }
            
            let justSavedProfile = KeychainWrapper.standard.string(forKey: "commonalityJustSavedProfile")
            
            if justSavedProfile != nil {
                if justSavedProfile == ApplicationConstants.commonalitySmallYesValue {
                    KeychainWrapper.standard.set(ApplicationConstants.commonalitySmallNoValue, forKey: "commonalityJustSavedProfile")
                    
                    emptyData()
                    commonalityTableView.reloadData()
                    
                    // Set user data
                    setUserData()
                    
                    // Save the device token to the database
                    saveCurrentDeviceToken()
                    
                    // Save the device ARN to the database
                    saveCurrentDeviceTokenAndArn()
                }
            }
            
            // Create remote folder
            manager = AWSUserFileManager.defaultUserFileManager()
            createRemoteFolder()
            
            getConnections()
        }
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 //sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfRows: Int = 0
        
        if currentUser != nil {
            if peopleSelected {
                if people.count > 0 {
                    numberOfRows = people.count
                }
            } else if foldersSelected {
                if peopleFolders.count > 0 {
                    numberOfRows = peopleFolders.count
                }
            } else {
                if buddies.count > 0 {
                    numberOfRows = buddies.count
                }
            }
        }

        return numberOfRows
    }
    
    
    
    
    // Set the table row height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    fileprivate struct Storyboard {
        // This value needs to be set in the attributes inspector properties section of the table cell, in the storyboard
        static let CellReuseIdentifier = "CommonalityMainCell"
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.CellReuseIdentifier, for: indexPath) as! CommonalityMainCell
        
        cell.selectionStyle = .none
        
        cell.folderOwnerImageView.isHidden = true
        cell.chatButtonActivityIndicatorView.isHidden = true
        
        // This is run of the user is logged in
        if currentUser != nil {
            // This runs of the people button is tapped
            if peopleSelected {
                cell.chatButton.isHidden = false
                cell.chatButton.isEnabled = true
                
                let greenish = UIColor(red: 45.0/255.0, green: 182.0/255.0, blue: 174.0/255.0, alpha: 1.0)
                
                let imageLayer: CALayer?  = cell.userImageView.layer
                imageLayer!.cornerRadius = cell.userImageView.frame.height / 2
                imageLayer!.borderWidth = 2.0
                imageLayer!.borderColor = UIColor.white.cgColor
                imageLayer!.masksToBounds = true
                
                cell.borderView.isHidden = false
                
                let borderLayer: CALayer?  = cell.borderView.layer
                borderLayer!.cornerRadius = cell.borderView.frame.height / 2
                borderLayer!.borderWidth = 2.5
                borderLayer!.borderColor = greenish.cgColor
                borderLayer!.masksToBounds = true
                
                cell.userImageView.image = #imageLiteral(resourceName: "empy_profile_pic")

                if people.count > indexPath.row {
                    let person = people[indexPath.row]
                    if person.key! == currentUser! {
                        cell.userNameLabel.text = "Me"
                    } else {
                       cell.userNameLabel.text = person.fullName!
                    }
                    
                    if person.institution != nil {
                        cell.institutionLabel.text = person.institution!
                    }
                    
                    if person.roleDetails != nil {
                        cell.roleLabel.text = person.roleDetails!
                    }
                    
                    if person.profilePictureFileName! != ApplicationConstants.dbEmptyValue {
                        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
                        let documentDirectoryURL = URL(fileURLWithPath: documentDirectory)
                        
                        if person.key != nil {
                            let fileName = person.key! + ".jpg"
                            let downloadFileURL = documentDirectoryURL.appendingPathComponent(fileName)
                            
                            /// Download or insert inmage into the cell if it already exists locally
                            if FileManager.default.fileExists(atPath: downloadFileURL.path) {
                                self.insertCommonalityImage(cell.userImageView, downloadFileURL: downloadFileURL)
                            } else {
                                self.setCommonalityCellProfilePic(imageView: cell.userImageView, profilePictureFileName: person.profilePictureFileName!, fileNameToSaveAs: fileName)
                            }
                        }
                    }
                    
                    if currentUser == person.key {
                        cell.chatButton.isEnabled = false
                    }
                    
                    // Open up the chat view controller when the chat button is tapped
                    cell.onChatButtonTapped = {
                        cell.chatButtonActivityIndicatorView.isHidden = false
                        cell.chatButtonActivityIndicatorView.startAnimating()
                        cell.chatButton.isEnabled = false
                        
                        self.messageID = nil
                        self.selectedChatRecipient = nil
                        self.selectedChatRecipientName = nil
                        
                        if person.key != nil && self.currentUser != nil {
                            self.selectedChatRecipient = person.key!
                            self.selectedChatRecipientName = person.fullName!
                            
                            // This section of code finds message ID for an existing thread
                            // or passes a nil to the segue
                            if person.key! != self.currentUser! {
                                let dBase = Firestore.firestore()
                                
                                let messageRef = dBase.collection("users").document(self.currentUser!).collection("messages")
                                
                                messageRef.getDocuments { (querySnapshot, error) in
                                    if error == nil {
                                        if let queryDocumentSnapshot = querySnapshot?.documents {
                                            if queryDocumentSnapshot.count == 0 {
                                                //self.chatButton.isEnabled = true
                                            }
                                            
                                            for data in queryDocumentSnapshot {
                                                let messageDict = data.data()
                                                
                                                if let recipientID = messageDict["recipient"] as? String {
                                                    if recipientID == person.key! {
                                                        self.messageID = data.documentID
                                                        
                                                        break
                                                    }
                                                }
                                            }
                                            
                                            cell.chatButtonActivityIndicatorView.isHidden = true
                                            cell.chatButtonActivityIndicatorView.stopAnimating()
                                            cell.chatButton.isEnabled = true
                                            
                                            self.performSegue(withIdentifier: "OpenMessagesFromHome", sender: nil)
                                        } else {
                                            cell.chatButtonActivityIndicatorView.isHidden = true
                                            cell.chatButtonActivityIndicatorView.stopAnimating()
                                            cell.chatButton.isEnabled = true
                                        }
                                    } else {
                                        cell.chatButtonActivityIndicatorView.isHidden = true
                                        cell.chatButtonActivityIndicatorView.stopAnimating()
                                        cell.chatButton.isEnabled = true
                                    }
                                }
                            }
                        }
                    }
                }
            } else if foldersSelected { // This runs when the folder button is tapped
                cell.chatButton.isHidden = true
                cell.chatButton.isEnabled = false
                
                if peopleFolders.count > indexPath.row {
                    let person = peopleFolders[indexPath.row]
                    
                    let fullName = person.fullName!
                    let fullNameArr = fullName.components(separatedBy: " ")
                    let firstName = fullNameArr[0]
                    
                    let imageLayer: CALayer?  = cell.userImageView.layer
                    imageLayer!.cornerRadius = 0
                    imageLayer!.borderWidth = 0
                    imageLayer!.borderColor = UIColor.clear.cgColor
                    imageLayer!.masksToBounds = true
                    
                    cell.borderView.isHidden = true
                    
                    if person.key! == currentUser! {
                        cell.userNameLabel.text = "My Folder"
                        cell.userImageView.image = #imageLiteral(resourceName: "folder-icon-small")
                    } else {
                        cell.userNameLabel.text = firstName + "'s Folder"
                        cell.userImageView.image = #imageLiteral(resourceName: "folder-icon-small")
                    }
                    
                    if person.institution != nil {
                        cell.institutionLabel.text = person.institution!
                    }
                    
                    if person.roleDetails != nil {
                        cell.roleLabel.text = person.roleDetails!
                    }
                    
                    cell.folderOwnerImageView.isHidden = false
                    cell.folderOwnerImageView.image = #imageLiteral(resourceName: "empy_profile_pic")
                    
                    let folderImageLayer: CALayer?  = cell.folderOwnerImageView.layer
                    folderImageLayer!.cornerRadius = cell.folderOwnerImageView.frame.height / 2
                    folderImageLayer!.masksToBounds = true
                    
                    if person.profilePictureFileName! != ApplicationConstants.dbEmptyValue {
                        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
                        let documentDirectoryURL = URL(fileURLWithPath: documentDirectory)
                        
                        if person.key != nil {
                            let fileName = person.key! + ".jpg"
                            let downloadFileURL = documentDirectoryURL.appendingPathComponent(fileName)
                            
                            /// Download or insert inmage into the cell if it already exists locally
                            if FileManager.default.fileExists(atPath: downloadFileURL.path) {
                                self.insertCommonalityImage(cell.folderOwnerImageView, downloadFileURL: downloadFileURL)
                            } else {
                                self.setCommonalityCellProfilePic(imageView: cell.folderOwnerImageView, profilePictureFileName: person.profilePictureFileName!, fileNameToSaveAs: fileName)
                            }
                        }
                    }
                }
            } else {
                cell.chatButton.isHidden = false
                cell.chatButton.isEnabled = true
                
                let greenish = UIColor(red: 45.0/255.0, green: 182.0/255.0, blue: 174.0/255.0, alpha: 1.0)
                
                let imageLayer: CALayer?  = cell.userImageView.layer
                imageLayer!.cornerRadius = cell.userImageView.frame.height / 2
                imageLayer!.borderWidth = 2.0
                imageLayer!.borderColor = UIColor.white.cgColor
                imageLayer!.masksToBounds = true
                
                cell.borderView.isHidden = false
                
                let borderLayer: CALayer?  = cell.borderView.layer
                borderLayer!.cornerRadius = cell.borderView.frame.height / 2
                borderLayer!.borderWidth = 2.5
                borderLayer!.borderColor = greenish.cgColor
                borderLayer!.masksToBounds = true
                
                cell.userImageView.image = #imageLiteral(resourceName: "empy_profile_pic")
                
                if buddies.count > indexPath.row { // This is when the buddies button is tapped
                    let buddy = buddies[indexPath.row]
                    if buddy.key! == currentUser! {
                        cell.userNameLabel.text = "Me"
                    } else {
                        cell.userNameLabel.text = buddy.fullName!
                    }
                    
                    if buddy.institution != nil {
                        cell.institutionLabel.text = buddy.institution!
                    }
                    
                    if buddy.roleDetails != nil {
                        cell.roleLabel.text = buddy.roleDetails!
                    }
                    
                    if buddy.profilePictureFileName! != ApplicationConstants.dbEmptyValue {
                        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
                        let documentDirectoryURL = URL(fileURLWithPath: documentDirectory)
                        
                        if buddy.key != nil {
                            let fileName = buddy.key! + ".jpg"
                            let downloadFileURL = documentDirectoryURL.appendingPathComponent(fileName)
                            
                            /// Download or insert inmage into the cell if it already exists locally
                            if FileManager.default.fileExists(atPath: downloadFileURL.path) {
                                self.insertCommonalityImage(cell.userImageView, downloadFileURL: downloadFileURL)
                            } else {
                                self.setCommonalityCellProfilePic(imageView: cell.userImageView, profilePictureFileName: buddy.profilePictureFileName!, fileNameToSaveAs: fileName)
                            }
                        }
                    }
                    
                    // Open up the chat view controller when the chat button is tapped
                    cell.onChatButtonTapped = {
                        cell.chatButtonActivityIndicatorView.isHidden = false
                        cell.chatButtonActivityIndicatorView.startAnimating()
                        cell.chatButton.isEnabled = false
                        
                        self.messageID = nil
                        self.selectedChatRecipient = nil
                        self.selectedChatRecipientName = nil
                        
                        if buddy.key != nil && self.currentUser != nil {
                            self.selectedChatRecipient = buddy.key!
                            self.selectedChatRecipientName = buddy.fullName!
                            
                            // This section of code finds message ID for an existing thread
                            // or passes a nil to the segue
                            if buddy.key! != self.currentUser! {
                                let dBase = Firestore.firestore()
                                
                                let messageRef = dBase.collection("users").document(self.currentUser!).collection("messages")
                                
                                messageRef.getDocuments { (querySnapshot, error) in
                                    if error == nil {
                                        if let queryDocumentSnapshot = querySnapshot?.documents {
                                            if queryDocumentSnapshot.count == 0 {
                                                //self.chatButton.isEnabled = true
                                            }
                                            
                                            for data in queryDocumentSnapshot {
                                                let messageDict = data.data()
                                                
                                                if let recipientID = messageDict["recipient"] as? String {
                                                    if recipientID == buddy.key! {
                                                        self.messageID = data.documentID
                                                        
                                                        break
                                                    }
                                                }
                                            }
                                            
                                            cell.chatButtonActivityIndicatorView.isHidden = true
                                            cell.chatButtonActivityIndicatorView.stopAnimating()
                                            cell.chatButton.isEnabled = true
                                            
                                            self.performSegue(withIdentifier: "OpenMessagesFromHome", sender: nil)
                                        } else  {
                                            cell.chatButtonActivityIndicatorView.isHidden = true
                                            cell.chatButtonActivityIndicatorView.stopAnimating()
                                            cell.chatButton.isEnabled = true
                                        }
                                    } else {
                                        cell.chatButtonActivityIndicatorView.isHidden = true
                                        cell.chatButtonActivityIndicatorView.stopAnimating()
                                        cell.chatButton.isEnabled = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true

        if foldersSelected {
            selectedFolderOwner = peopleFolders[indexPath.row].key
            
            if peopleFolders[indexPath.row].fullName != nil {
                let fullName = peopleFolders[indexPath.row].fullName!
                let fullNameArr = fullName.components(separatedBy: " ")
                let firstName = fullNameArr[0]
                
                selectedFolderOwnerFirstName = firstName
            }
            
            if currentUser != nil {
                self.performSegue(withIdentifier: "OpenUserFolder", sender: nil)
            } else {
                self.displayCommonalityGenericAlert("Please login", userMessage: "Please login to view this folder.")
            }
        } else if peopleSelected {
            selectedFolderOwner = people[indexPath.row].key
            
            if currentUser != nil {
                self.performSegue(withIdentifier: "OpenProfileFromHome", sender: nil)
            } else {
                self.displayCommonalityGenericAlert("Please login", userMessage: "Please login to view this user.")
            }
        } else {
            selectedFolderOwner = buddies[indexPath.row].key
            
            if currentUser != nil {
                self.performSegue(withIdentifier: "OpenProfileFromHome", sender: nil)
            } else {
                self.displayCommonalityGenericAlert("Please login", userMessage: "Please login to view this user.")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let rotationTransform = CATransform3DTranslate(CATransform3DIdentity, -500, 10, 0)
        cell.layer.transform = rotationTransform
        
        UIView.animate(withDuration: 0.5) {
            cell.layer.transform = CATransform3DIdentity
        }
    }
    
    // The login button tapped function
    @IBAction func loginButtonTapped(_ sender: Any) {
        userComesFromLogin = true
        
        if self.navigationItem.leftBarButtonItem!.title! == ApplicationConstants.commonalityLoginButtonValue {
            self.performSegue(withIdentifier: "openLoginFromHome", sender: nil)
        } else {
            pickContact()
        }
    }
    

    
    
    // MARK: - Helpers
    //// Open the login/signup page
    @objc func timedSegueToOnboarder() {
        self.performSegue(withIdentifier: "openLoginFromHome", sender: nil)
    }
    
    /**
     This enables all the tabs the logged in tabs.
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func enableAllTabs() {
        let parentTabBarController = self.tabBarController
        
        let arrayOfTabBarItems = parentTabBarController?.tabBar.items as [UITabBarItem]?
        
        if arrayOfTabBarItems != nil {
            let tabBarItem0 = arrayOfTabBarItems![0]
            tabBarItem0.isEnabled = true
            let tabBarItem1 = arrayOfTabBarItems![1]
            tabBarItem1.isEnabled = true
            let tabBarItem2 = arrayOfTabBarItems![2]
            tabBarItem2.isEnabled = true
            let tabBarItem3 = arrayOfTabBarItems![3]
            tabBarItem3.isEnabled = true
        }
    }
    
    /**
     This disables all the tabs besides the selected index.
     
     - Parameters:
     - index: The selected index
     
     - Returns: void.
     */
    func disableTabsButCurrentIndex(index: Int) {
        let parentTabBarController = self.tabBarController
        
        let arrayOfTabBarItems = parentTabBarController?.tabBar.items as [UITabBarItem]?
        
        var currentIndex = 0
        
        if arrayOfTabBarItems != nil {
            for tabBarItem in arrayOfTabBarItems! {
                if currentIndex != index {
                    tabBarItem.isEnabled = false
                }
                
                currentIndex += 1
            }
        }
    }
    
    
    @IBAction func joinTripButtonTapped(_ sender: Any) {
        self.definesPresentationContext = true
        self.providesPresentationContextTransitionStyle = true
    }
    
    
    /**
     Downloads the profile pic from S3, stores it locally and inserts it into the cell.
     
     - Parameters:
     - imageView: The profile pic image view
     - fileName: The name of the file as it is store on S3
     - downloadULR: The local storage url
     
     - Returns: void.
     */
    func downloadImage(_ imageView: UIImageView, downloadFileURL: String, fileNameToSaveAs: String) {
        /// When signing up, the user image is stored as "empty"
        if downloadFileURL != ApplicationConstants.dbEmptyValue {
            /// Get a reference to the image using the URL
            let ref = Storage.storage().reference(forURL: downloadFileURL)
            
            /// Get the image data
            ref.getData(maxSize: 10 * 1024 * 1024, completion: { (data, error) in
                if error != nil {
                    print(ApplicationConstants.profilePictureDownloadErrorMessage)
                } else {
                    if let imageData = data {
                        if let image = UIImage(data: imageData) {
                            imageView.alpha = 0
                            
                            imageView.image = image
                            UIView.animate(withDuration: 0.5, animations: { () -> Void in
                                imageView.alpha = 1
                            })
                            
                            /// Store the image on the phone
                            if fileNameToSaveAs != ApplicationConstants.dbEmptyValue {
                            
                                /// The directory of the documents folder
                                let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
                                
                                /// The URL of the documents folder
                                let documentDirectoryURL = URL(fileURLWithPath: documentDirectory)
                                
                                /// The local URL of the profile pic
                                let localURL = documentDirectoryURL.appendingPathComponent(fileNameToSaveAs)
                                
                                /// The local paths of the URLs
                                let localPath = localURL.path
                                
                                /// Write the image data to file
                                try? imageData.write(to: URL(fileURLWithPath: localPath), options: [.atomic])
                            }
                        }
                    }
                }
            })
        }
    }
    
    
    /**
     Retrives the profile pic locally and inserts it into the cell.
     
     - Parameters:
     - cell: The Spreebie collection view cell
     - fileName: The name of the file as it is stored locally
     - downloadULR: The local storage url
     
     - Returns: void.
     */
    func insertCommonalityImage(_ imageView: UIImageView, downloadFileURL: URL) {
        DispatchQueue.main.async(execute: { () -> Void in
            if UIImage(named: downloadFileURL.path) != nil {
                /// On success, insert the image
                let image = UIImage(named: downloadFileURL.path)
                imageView.alpha = 0
                
                imageView.image = image
                UIView.animate(withDuration: 0.5, animations: { () -> Void in
                    imageView.alpha = 1
                })
            }
        })
    }

    
    /**
     Set the user's data.
     
     - Parameters:
     - none
     
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
                        if let fullName = userDict["fullName"] as? String, let profilePictureFileName = userDict["profilePictureFileName"] as? String {
                            
                            /// Set the text data
                            self.userNameLabel.text = fullName
                            self.currentUserName = fullName
                            
                            /// Set the profile picture data
                            if profilePictureFileName != ApplicationConstants.dbEmptyValue {
                                self.profilePictureFileName = profilePictureFileName
                                
                                let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
                                let documentDirectoryURL = URL(fileURLWithPath: documentDirectory)
                                
                                if self.currentUser != nil {
                                    let fileName = self.currentUser! + ".jpg"
                                    let downloadFileURL = documentDirectoryURL.appendingPathComponent(fileName)
                                    
                                    /// Download or insert inmage into the cell if it already exists locally
                                    if FileManager.default.fileExists(atPath: downloadFileURL.path) {
                                        self.insertCommonalityImage(self.profilePictureImageView, downloadFileURL: downloadFileURL)
                                    } else {
                                        self.setProfilePic(fileNameToSaveAs: fileName)
                                    }
                                }
                            }
                            
                            if let school = userDict["school"] as? String {
                                self.schoolLabel.text = school
                                self.currentUserSchool = school
                            }
                            
                            if let role = userDict["role"] as? String {
                                self.currentUserRole = role
                                
                                if role == "student" {
                                    if let roleDetails = userDict["roleDetails"] as? String {
                                        self.roleLabel.text = roleDetails
                                        self.currentUserRoleDetails = roleDetails
                                    }
                                } else {
                                    if let roleDetails = userDict["roleDetails"] as? String {
                                        self.roleLabel.text = roleDetails
                                        self.currentUserRoleDetails = roleDetails
                                    }
                                }
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

    
    /**
     Downloads the profile pic.
     
     - Parameters:
     - imageView: The profile pic image view
     - fileName: The name of the file as it is store on S3
     - downloadULR: The local storage url
     
     - Returns: void.
     */
    func setProfilePic(fileNameToSaveAs: String) {
        /// When signing up, the user image is stored as "empty"
        if profilePictureFileName != ApplicationConstants.dbEmptyValue {
            /// Get a reference to the image using the URL
            let ref = Storage.storage().reference(forURL: self.profilePictureFileName)
            
            /// Get the image data
            ref.getData(maxSize: 10 * 1024 * 1024, completion: { (data, error) in
                if error != nil {
                    print(ApplicationConstants.profilePictureDownloadErrorMessage)
                } else {
                    if let imageData = data {
                        if let image = UIImage(data: imageData) {
                            self.profilePictureImageView.alpha = 0
                            let imageLayer: CALayer?  = self.profilePictureImageView.layer
                            imageLayer!.cornerRadius = self.profilePictureImageView.frame.height / 2
                            imageLayer!.masksToBounds = true
                            
                            self.profilePictureImageView.image = image
                            UIView.animate(withDuration: 0.5, animations: { () -> Void in
                                self.profilePictureImageView.alpha = 1
                            })
                            
                            /// Store the image on the phone
                            if fileNameToSaveAs != "empty" {
                                
                                /// The directory of the documents folder
                                let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
                                
                                /// The URL of the documents folder
                                let documentDirectoryURL = URL(fileURLWithPath: documentDirectory)
                                
                                /// The local URL of the profile pic
                                let localURL = documentDirectoryURL.appendingPathComponent(fileNameToSaveAs)
                                
                                /// The local paths of the URLs
                                let localPath = localURL.path
                                
                                /// Write the image data to file
                                try? imageData.write(to: URL(fileURLWithPath: localPath), options: [.atomic])
                            }
                        }
                    }
                }
            })
        }
    }
    
    /**
     Convert the time stamp to a readable date
     
     - Parameters:
     - timeStamp: The timestamp as an int
     
     - Returns: void.
     */
    func convertTimeStampToDate(timeStamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timeStamp))
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.medium //Set time style
        dateFormatter.dateStyle = DateFormatter.Style.medium //Set date style
        let localDate = dateFormatter.string(from: date)
        
        return localDate
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /// Has a segue just happened
        ApplicationConstants.hasASeguedHappenedInTheHomePage = true
        
        if (segue.identifier == "OpenUserFolder") {
            weak var ufvc = segue.destination as? UserFilesViewController
            
            ufvc?.folderOwner = selectedFolderOwner
            ufvc?.ownerFirstName = selectedFolderOwnerFirstName
        }
        
        if (segue.identifier == "OpenProfileFromHome") {
            weak var mupvc = segue.destination as? CommonalityUserProfileViewController
            
            mupvc?.pickedUser = selectedFolderOwner
            mupvc?.currentUserConnections = self.connections
            mupvc?.currentUserName = currentUserName
        }
        
        if (segue.identifier == "OpenPopupFromHome") {
            weak var spvc = segue.destination as? StandardPopupViewController
            
            spvc!.selectedTabIndex = 0
            spvc!.informativeText = "Invite a friend near you to install Commonality so your can both be on the same mesh network. Tap the \"Invite\" button."
        }
        
        if (segue.identifier == "OpenMessagesFromHome") {
            weak var mvc = segue.destination as? MessagesViewController
            
            mvc!.recipient = selectedChatRecipient!
            mvc!.messageID = messageID
            mvc!.recipientName = selectedChatRecipientName!
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "OpenUserFolder" {
            if currentUser == nil {
                self.displayCommonalityGenericAlert("Please login", userMessage: "Please login to view this folder.")
                return false
            }
        }
        
        if identifier == "OpenProfileFromHome" {
            if currentUser == nil {
                self.displayCommonalityGenericAlert("Please login", userMessage: "Please login to view this users.")
                return false
            }
        }
        
        return true
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
    
    func emptyData() {
        /*pastTrips.removeAll()
        upcomingTrips.removeAll()
        sortedPastTrips.removeAll()
        sortedUpcomingTrips.removeAll()*/
    }
    
    @objc func handleRefresh(refreshControl: UIRefreshControl) {
        // Start the activity indicator
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        if currentUser != nil {
            emptyData()
            
            if !self.connectedDevices.contains(self.currentUser!) {
                self.connectedDevices.append(self.currentUser!)
            }
            
            if peopleSelected {
                populatePeople()
            } else if foldersSelected {
                populateFolders()
            } else {
                populateBuddies()
            }
            
            setUserData()
            
            saveCurrentDeviceToken()
            saveCurrentDeviceTokenAndArn()
            
            refreshControl.endRefreshing()
        } else {
            emptyData()
            commonalityTableView.reloadData()
        }
        
        refreshControl.endRefreshing()
    }
    
    @IBAction func refreshBarButtonItemTapped(_ sender: Any) {
        // Start the activity indicator
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        if currentUser == nil {
            emptyData()
            commonalityTableView.reloadData()
        } else {
            emptyData()
            
            if !self.connectedDevices.contains(self.currentUser!) {
                self.connectedDevices.append(self.currentUser!)
            }
            
            if peopleSelected {
                populatePeople()
            } else if foldersSelected {
                populateFolders()
            } else {
                populateBuddies()
            }
            
            // Set user data
            setUserData()
            
            saveCurrentDeviceToken()
            saveCurrentDeviceTokenAndArn()
        }
    }
    
    /**
     Animates the table view.
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func animateTable() {
        commonalityTableView.reloadData()
        
        let cells = commonalityTableView.visibleCells
        let tableHeight: CGFloat = commonalityTableView.bounds.size.height
        
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
                            //let key = data.documentID
                            
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
     Populates the people array
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func populatePeople() {
        if currentUser != nil {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            self.count = 0
            people.removeAll()
            
            // Get firestore dBase
            let dBase = Firestore.firestore()
                
            if !self.connectedDevices.contains(self.currentUser!) {
                self.connectedDevices.append(self.currentUser!)
            }
            
            print("Inside populatePeople: \(connectedDevices)")
            
            let connectedDevicesCopy = connectedDevices
            
            // Loop through all the device currently on the mesh network
            for connectedDevice in connectedDevicesCopy {
                // Get the reference
                let userRef = dBase.collection("users").document(connectedDevice)
                
                userRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        if let userDict = document.data() {
                            /// Create a user from the dictionary
                            let user = User(key: connectedDevice, userData: userDict as Dictionary<String, AnyObject>)
                            self.people.append(user)
                            
                            /// Increase the count by one
                            self.count += 1
                            
                            /// If we've looped through all the snapshot records
                            if self.count == connectedDevicesCopy.count {
                                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                self.commonalityTableView.reloadData()
                                
                                self.matchUsers()
                            }
                        }
                    } else {
                        print("Error: \(String(describing: error?.localizedDescription))")
                    }
                }
            }
            
            if self.connectedDevices.count == 0 {
                commonalityTableView.reloadData()
            }
        }
    }
    
    
    /**
     Populates the folder array
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func populateFolders() {
        if currentUser != nil {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            self.count2 = 0
            peopleFolders.removeAll()
            
            // Get firestore dBase
            let dBase = Firestore.firestore()
            
            // Loop through all the device currently on the mesh network
            for folder in folders {
                // Get the reference
                let userRef = dBase.collection("users").document(folder)
                
                userRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        if let userDict = document.data() {
                            /// Create a user from the dictionary
                            let user = User(key: folder, userData: userDict as Dictionary<String, AnyObject>)
                            self.peopleFolders.append(user)
                            
                            /// Increase the count by one
                            self.count2 += 1
                            
                            /// If we've looped through all the snapshot records
                            if self.count2 == self.folders.count {
                                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                self.commonalityTableView.reloadData()
                            }
                        }
                    } else {
                        print("Error: \(String(describing: error?.localizedDescription))")
                    }
                }
            }
            
            if self.folders.count == 0 {
                commonalityTableView.reloadData()
            }
        }
    }
    
    
    /**
     Populates the folder array
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func populateBuddies() {
        if currentUser != nil {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            self.count5 = 0
            buddies.removeAll()
            
            // Get firestore dBase
            let dBase = Firestore.firestore()
            
            // Loop through all the device currently on the mesh network
            for connection in connections {
                // Get the reference
                let userRef = dBase.collection("users").document(connection)
                
                userRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        if let userDict = document.data() {
                            /// Create a user from the dictionary
                            let user = User(key: connection, userData: userDict as Dictionary<String, AnyObject>)
                            self.buddies.append(user)
                            
                            /// Increase the count by one
                            self.count5 += 1
                            
                            /// If we've looped through all the snapshot records
                            if self.count5 == self.connections.count {
                                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                self.commonalityTableView.reloadData()
                            }
                        }
                    } else {
                        print("Error: \(String(describing: error?.localizedDescription))")
                    }
                }
            }
            
            if self.connections.count == 0 {
                commonalityTableView.reloadData()
            }
        }
    }
    
    
    /**
     Set the proflle picture
     
     - Parameters:
     - imageView: The profile picture inage view
     - profilePictureFileName: The name of the image on the cloud
     - fileNameToSaveAs: The name of the file on the phone
     
     - Returns: void.
     */
    func setCommonalityCellProfilePic(imageView: UIImageView, profilePictureFileName: String, fileNameToSaveAs: String) {
        /// When signing up, the user image is stored as "empty"
        if profilePictureFileName != ApplicationConstants.dbEmptyValue {
            /// Get a reference to the image using the URL
            let ref = Storage.storage().reference(forURL: profilePictureFileName)
            
            /// Get the image data
            ref.getData(maxSize: 10 * 1024 * 1024, completion: { (data, error) in
                if error != nil {
                    print(ApplicationConstants.profilePictureDownloadErrorMessage)
                } else {
                    if !self.foldersSelected {
                        if let imageData = data {
                            if let image = UIImage(data: imageData) {
                                imageView.alpha = 0
                                let imageLayer: CALayer?  = imageView.layer
                                imageLayer!.cornerRadius = imageView.frame.height / 2
                                imageLayer!.masksToBounds = true
                                
                                imageView.image = image
                                UIView.animate(withDuration: 0.5, animations: { () -> Void in
                                    imageView.alpha = 1
                                })
                                
                                /// Store the image on the phone
                                if fileNameToSaveAs != "empty" {
                                    
                                    /// The directory of the documents folder
                                    let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
                                    
                                    /// The URL of the documents folder
                                    let documentDirectoryURL = URL(fileURLWithPath: documentDirectory)
                                    
                                    /// The local URL of the profile pic
                                    let localURL = documentDirectoryURL.appendingPathComponent(fileNameToSaveAs)
                                    
                                    /// The local paths of the URLs
                                    let localPath = localURL.path
                                    
                                    /// Write the image data to file
                                    try? imageData.write(to: URL(fileURLWithPath: localPath), options: [.atomic])
                                }
                            }
                        }
                    }
                }
            })
        }
    }
    
    
    /**
     Set the folder picture
     
     - Parameters:
     - imageView: The profile picture inage view
     - profilePictureFileName: The name of the image on the cloud
     
     - Returns: void.
     */
    func setCommonalityCellFolderProfilePic(imageView: UIImageView, profilePictureFileName: String) {
        /// When signing up, the user image is stored as "empty"
        if profilePictureFileName != ApplicationConstants.dbEmptyValue {
            /// Get a reference to the image using the URL
            let ref = Storage.storage().reference(forURL: profilePictureFileName)
            
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
    
    // Create the user folder's unique key
    func createFolderForKey(_ key: String) {
        let localContent = manager.localContent(with: nil, key: key)
        //uploadLocalContent(localContent)
        localContent.uploadWithPin(onCompletion: false, progressBlock: {[weak self] (content: AWSLocalContent, progress: Progress) in
            // do nothing
        })
    }
    
    
    /**
     Create a remote folder
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func createRemoteFolder() {
        if currentUser != nil {
            // Get firestore dBase
            let dBase = Firestore.firestore()
            
            let userRef = dBase.collection("users").document(currentUser!)
            
            userRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    if let userDict = document.data() {
                        /// Check for nil again
                        if let remoteFolderCreated = userDict["remoteFolderCreated"] as? String {
                            // do nothing
                        } else {
                            let s3 = AWSS3.default()
                            
                            let putObjectRequest = AWSS3PutObjectRequest()
                            
                            putObjectRequest?.key = "public/" + self.currentUser! + "/";
                            putObjectRequest?.bucket = ApplicationConstants.commonalityS3Bucket
                            putObjectRequest?.body = nil;
                            
                            s3.putObject(putObjectRequest!, completionHandler: { (output, error) in
                                if error == nil {
                                    let userData = [
                                        "remoteFolderCreated": "YES"
                                        ] as [String : Any]
                                    
                                    userRef.updateData(userData)
                                }
                            })
                        }
                    }
                } else {
                    print("Error: \(String(describing: error?.localizedDescription))")
                }
            }
        }
    }
    
    // People button action
    @IBAction func peopleButtonTapped(_ sender: Any) {
        if currentUser != nil {
            let purplish = UIColor(red: 192.0/255.0, green: 30.0/255.0, blue: 201.0/255.0, alpha: 1.0)
            
            joinTripButton.layer.backgroundColor = purplish.cgColor
            joinTripButton.setTitleColor(UIColor.white, for: .normal)
            
            createTripButton.layer.backgroundColor = UIColor.white.cgColor
            createTripButton.setTitleColor(purplish, for: .normal)
            
            createTripButton.layer.borderWidth = 1
            createTripButton.layer.borderColor = purplish.cgColor
            
            buddiesButton.layer.backgroundColor = UIColor.white.cgColor
            buddiesButton.setTitleColor(purplish, for: .normal)
            
            buddiesButton.layer.borderWidth = 1
            buddiesButton.layer.borderColor = purplish.cgColor
            
            peopleSelected = true
            foldersSelected = false
            buddiesSelected = false
            
            populatePeople()
        }
    }
    
    // Folder button action
    @IBAction func foldersButtonTapped(_ sender: Any) {
        if currentUser != nil {
            let purplish = UIColor(red: 192.0/255.0, green: 30.0/255.0, blue: 201.0/255.0, alpha: 1.0)
            
            createTripButton.layer.backgroundColor = purplish.cgColor
            createTripButton.setTitleColor(UIColor.white, for: .normal)
            
            joinTripButton.layer.backgroundColor = UIColor.white.cgColor
            joinTripButton.setTitleColor(purplish, for: .normal)
            
            joinTripButton.layer.borderWidth = 1
            joinTripButton.layer.borderColor = purplish.cgColor
            
            buddiesButton.layer.backgroundColor = UIColor.white.cgColor
            buddiesButton.setTitleColor(purplish, for: .normal)
            
            buddiesButton.layer.borderWidth = 1
            buddiesButton.layer.borderColor = purplish.cgColor
            
            peopleSelected = false
            foldersSelected = true
            buddiesSelected = false
            
            folders.removeAll()
            
            for connectedDevice in connectedDevices {
                folders.append(connectedDevice)
            }
            
            populateFolders()
            
            if !foldersTooltipHasBeenShow {
            AMTooltipView(message: "Upload your files into 'My Folder'. Everything you place in this folder can be seen by your peers.",
                          focusView: createTripButton, //pass view you want show tooltip over it
                target: self)
                
                foldersTooltipHasBeenShow = true
            }
        }
    }
    
    // Buddies button action
    @IBAction func buddiesButtonTapped(_ sender: Any) {
        if currentUser != nil {
            let purplish = UIColor(red: 192.0/255.0, green: 30.0/255.0, blue: 201.0/255.0, alpha: 1.0)
            
            buddiesButton.layer.backgroundColor = purplish.cgColor
            buddiesButton.setTitleColor(UIColor.white, for: .normal)
            
            joinTripButton.layer.backgroundColor = UIColor.white.cgColor
            joinTripButton.setTitleColor(purplish, for: .normal)
            
            joinTripButton.layer.borderWidth = 1
            joinTripButton.layer.borderColor = purplish.cgColor
            
            createTripButton.layer.backgroundColor = UIColor.white.cgColor
            createTripButton.setTitleColor(purplish, for: .normal)
            
            createTripButton.layer.borderWidth = 1
            createTripButton.layer.borderColor = purplish.cgColor
            
            buddiesSelected = true
            peopleSelected = false
            foldersSelected = false
            
            populateBuddies()
            
            if !buddiesTooltipHasBeenShow {
                AMTooltipView(message: "Connect with your peers so that they can become your buddies. Once you are connected, you can chat even when you are not near each other.",
                          focusView: buddiesButton, //pass view you want show tooltip over it
                target: self)
                
                buddiesTooltipHasBeenShow = true
            }
            
        }
    }
    
    
    /**
     Populate the connections list
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func getConnections() {
        /// Check for nil
        if currentUser != nil {
            connections.removeAll()
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            // Get firestore dBase
            let dBase = Firestore.firestore()
            
            let connectionRef = dBase.collection("connections").document(currentUser!)
            
            connectionRef.getDocument { (document, error) in
                if error == nil {
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
                    
                    if self.connections.count == 0 {
                        if !self.popupShown {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                                self.performSegue(withIdentifier: "OpenPopupFromHome", sender: nil)
                            })
                            
                            self.popupShown = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: TagListViewDelegate
    func tagPressed(_ title: String, tagView: TagView, sender: TagListView) {
        tagView.isSelected = !tagView.isSelected
    }
    
    func tagRemoveButtonPressed(_ title: String, tagView: TagView, sender: TagListView) {
        sender.removeTagView(tagView)
    }
    
    /**
     This picks a contact and set the nature of the message
     
     - Parameters:
     - sender: The sender view
     
     - Returns: void.
     */
    func pickContact() {
        let alert = UIAlertController(title: "Invite a friend", message: "Choose a messaging type through which you will send your friend an invite.", preferredStyle: UIAlertControllerStyle.alert)
        
        /// SMS contact
        alert.addAction(UIAlertAction(title: "SMS", style: UIAlertActionStyle.default, handler: { (alert) -> Void in
            self.messageType = "SMS"
            
            let entityType = CNEntityType.contacts
            let authStatus = CNContactStore.authorizationStatus(for: entityType)
            
            if authStatus == CNAuthorizationStatus.notDetermined {
                let contactStore = CNContactStore.init()
                
                contactStore.requestAccess(for: entityType, completionHandler: { (success, nil) in
                    if success {
                        
                    } else {
                        print("Not authorized.")
                    }
                })
            } else if authStatus == CNAuthorizationStatus.authorized {
                self.openContacts()
            } else if authStatus == CNAuthorizationStatus.denied {
                self.displayCommonalityGenericAlert("Previously denied", userMessage: "Access to contacts was denied. You can change this in your phone's settings.")
            }
        }))
        
        // Email contact
        alert.addAction(UIAlertAction(title: "Email", style: UIAlertActionStyle.default, handler: { (alert) -> Void in
            self.messageType = "Email"
            
            let entityType = CNEntityType.contacts
            let authStatus = CNContactStore.authorizationStatus(for: entityType)
            
            if authStatus == CNAuthorizationStatus.notDetermined {
                let contactStore = CNContactStore.init()
                
                contactStore.requestAccess(for: entityType, completionHandler: { (success, nil) in
                    if success {
                        
                    } else {
                        print("Not authorized.")
                    }
                })
            } else if authStatus == CNAuthorizationStatus.authorized {
                self.openContacts()
            } else if authStatus == CNAuthorizationStatus.denied {
                self.displayCommonalityGenericAlert("Previously denied", userMessage: "Access to contacts was denied. You can change this in your phone's settings.")
            }
        }))
        
        /// Cancel the action
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: { (alert) -> Void in
            //self.createSpreebieBarButtonItem.isEnabled = true
        }))
        
        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    /**
     This is an delegate method that opens up a contact picker and
     and assigns the to attributes in the application
     
     - Parameters:
     - picker: The contact picker view controller
     = conctact: The selected contact
     
     - Returns: void.
     */
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        /// When the user selects a contact
        
        contactName = "\(contact.givenName) \(contact.familyName)"
        
        /// Assign the contactIdentifier
        if let type = messageType {
            if type == "SMS" {
                if !contact.phoneNumbers.isEmpty {
                    let phoneString = ((((contact.phoneNumbers[0] as AnyObject).value(forKey: "labelValuePair") as AnyObject).value(forKey: "value") as AnyObject).value(forKey: "stringValue"))
                    
                    contactIdentifier = phoneString! as? String
                    
                    if contactIdentifier == nil {
                        
                    } else {
                        Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(self.sendText), userInfo: nil, repeats: false)
                    }
                } else {
                    self.displayCommonalityGenericAlert("Contact number missing", userMessage: "The contact you selected has no number.")
                }
            } else if type == "Email" {
                if !contact.emailAddresses.isEmpty {
                    let emailString = (((contact.emailAddresses[0] as AnyObject).value(forKey: "labelValuePair") as AnyObject).value(forKey: "value"))
                    
                    contactIdentifier = emailString! as? String
                    
                    if contactIdentifier == nil {
                        
                    } else {
                        Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(self.sendEmail), userInfo: nil, repeats: false)
                    }
                } else {
                    self.displayCommonalityGenericAlert("Contact email missing", userMessage: "The contact you selected has no email.")
                }
            }
        }
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        //... handle sms screen actions
        self.dismiss(animated: true, completion: nil)
    }
    
    /// This sends a text
    @objc func sendText() {
        let commonalityInviteMessage = "Check out the amazing app Commonality that helps you learn about and interact with people near you without even speaking to them: \(ApplicationConstants.commonalityLandingPageURL)"
        
        if (MFMessageComposeViewController.canSendText()) {
            let controller = MFMessageComposeViewController()
            controller.body = commonalityInviteMessage
            controller.recipients = [contactIdentifier!]
            controller.messageComposeDelegate = self
            
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    /**
     Constructs the TellPal email.
     
     - Parameters:
     - none
     
     - Returns: MFMailComposeViewController.
     */
    func configuredMailComposeViewController(recipientName: String, recipient: String, title: String, message: String, hasImage: Bool, fileName: String?, imageData: NSData?) -> MFMailComposeViewController {
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self
        
        mailComposeViewController.setToRecipients([recipient])
        mailComposeViewController.setSubject(title)
        mailComposeViewController.setMessageBody(message, isHTML: false)
        if hasImage {
            mailComposeViewController.addAttachmentData(imageData! as Data, mimeType: "image/jpeg", fileName: fileName!)
        }
        
        return mailComposeViewController
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
        /// handle email actions
        self.dismiss(animated: true, completion: nil)
    }
    
    // This sends an email
    @objc func sendEmail() {
        let kascadeInviteMessage = "Check out the amazing app Commonality that helps you learn about and interact with people near you without even speaking to them: \(ApplicationConstants.commonalityLandingPageURL)"
        
        let mailComposeViewController = self.configuredMailComposeViewController(recipientName: contactName!, recipient: contactIdentifier!, title: "Check out Commonality!", message: kascadeInviteMessage, hasImage: false, fileName: nil, imageData: nil)
        
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.displayCommonalityGenericAlert("Could not send email", userMessage: "Your device could not send email. Please check your email setup and try again.")
        }
    }
    
    /**
     Opens a contact picker
     
     - Parameters:
     - none
     
     - Returns: nothing
     */
    func openContacts() {
        let contactPicker = CNContactPickerViewController.init()
        contactPicker.delegate = self
        self.present(contactPicker, animated: true, completion: nil)
    }
    
    /// Do nothing is contact picking is cancelled
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        picker.dismiss(animated: true) {
            
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
    
    // Checks if the matches array contains a particular user
    func containsMatch(person: User) -> Bool {
        for matchingUser in matches {
            if matchingUser.key! == person.key! {
                return true
            }
        }
        
        
        return false
    }
    
    
    /**
     This matches users with the same interests
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func matchUsers() {
        if currentUser != nil {
            var matchCount = 0
            
            /// First find the current user
            var me: User? = nil
            
            for person in people {
                if person.key! == currentUser! {
                    me = person
                }
            }
            
            for person in people {
                if person.key != currentUser {
                    if let interests = person.interests {
                        for interest in interests {
                            if let myInterests = me?.interests {
                                for myInterest in myInterests {
                                    if myInterest == interest {
                                        matchCount += 1
                                    }
                                    
                                    if matchCount == 3 {
                                        if person.fullName != nil && !containsMatch(person: person){
                                            sendMatchNotifications(userID: currentUser!, personFullName: person.fullName!)
                                            matches.append(person)
                                        }
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
     Displays an alert.
     
     - Parameters:
     - userID: The user ID of the match
     - personFullName: The current user name
     
     - Returns: void.
     */
    func sendMatchNotifications(userID: String, personFullName: String) {
        let dBase = Firestore.firestore()
        let messageRef = dBase.collection("users").document(userID)
        
        messageRef.getDocument { (querySnapshot, error) in
            if let userDict = querySnapshot?.data() {
                if let deviceArn = userDict["deviceArn"] as? String, let deviceTokenSNS = userDict["deviceTokenSNS"] as? String {
                    /// Push notification meant for the spreebie uploader
                    let sns = AWSSNS.default()
                    let request = AWSSNSPublishInput()
                    
                    request?.messageStructure = "json"
                    
                    /// The payload
                    let dict = ["default": "\(personFullName)'s interests match yours.", ApplicationConstants.commonalityAPNSType: "{\"aps\":{\"alert\": {\"title\":\"Match Found\",\"body\":\"\(personFullName)'s interests match yours.\"},\"sound\":\"default\",\"badge\":1} }"]
                    
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
                    
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
            }
        }
    }
    
    // The navigation controller related to the custom segue - the circular segue
    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.forward = (operation == .push)
        transition.startingPoint = view.center //selectedCell.userImageView.center
        transition.circleColor = UIColor.white
        
        return transition
    }
    
    // Disables the mesh network
    @objc func willResignActive(_ notification: Notification) {
        if commonalityService != nil {
            commonalityService!.delegate = nil
            commonalityService = nil
        }
    }
    
    // Activates the mesh network
    @objc func willBecomeActive(_ notification: Notification) {
        if commonalityService == nil {
            commonalityService = CommonalityServiceManager()
            commonalityService!.delegate = self
        }
    }
}

// This is an extension that impliments
extension HomeViewController : CommonalityServiceManagerDelegate {
    func connectedDevicesChanged(manager: CommonalityServiceManager, connectedDevices: [String]) {
        OperationQueue.main.addOperation {
            self.connectedDevices = connectedDevices
        
            self.populatePeople()
        }
    }
}
