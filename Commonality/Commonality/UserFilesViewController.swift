//
//  UserFilesViewController.swift
//  Commonality
//
//  Created by Thabo David Klass on 06/06/2018.
//  Copyright © 2018 Spreebie, Inc. All rights reserved.
//

import UIKit
import WebKit
import MobileCoreServices
import AWSMobileHubContentManager
import AWSAuthCore
import AVFoundation
import AVKit
import FirebaseFirestore
import Photos
import StoreKit

import ObjectiveC

let UserFilesPrivateDirectoryName = "private"
let UserFilesProtectedDirectoryName = "protected"
let UserFilesUploadsDirectoryName = "uploads"
let UserFilesStoryBoard = "Main"
private var cellAssociationKey: UInt8 = 0

class UserFileStorageViewController: UIViewController {
    
    @IBOutlet weak var featureTextView: UITextView!
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        featureTextView.contentInset = UIEdgeInsetsMake(-4, -4, -4, -4)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        featureTextView.flashScrollIndicators()
    }
    
    // MARK: - IBActions
    
    @IBAction func demoUserFileStorage(_ sender: UIButton){
        let storyboard = UIStoryboard(name: UserFilesStoryBoard, bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "UserFiles")
        navigationController!.pushViewController(viewController, animated: true)
    }
}

// This class is responsible for the cloud file storage
class UserFilesViewController: UITableViewController, SKProductsRequestDelegate, SKPaymentTransactionObserver, URLSessionDelegate, URLSessionDataDelegate {
    
    @IBOutlet weak var pathLabel: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var spaceUsedLabel: UILabel!
    @IBOutlet weak var buySpaceButton: UIButton!
    
    /// The current user
    let currentUser: String? = KeychainWrapper.standard.string(forKey: ApplicationConstants.commonalityUserIDKey)
    
    var folderOwner: String? = nil
    
    var UserFilesPublicDirectoryName = "public"
    
    var prefix: String!
    
    fileprivate var manager: AWSUserFileManager!
    fileprivate var contents: [AWSContent]?
    fileprivate var dateFormatter: DateFormatter!
    fileprivate var marker: String?
    fileprivate var didLoadAllContents: Bool!
    fileprivate var segmentedControlSelected: Int = 0;
    
    /// Creating UIDocumentInteractionController instance.
    let documentInteractionController = UIDocumentInteractionController()
    
    // In-App Section
    /// In-App purchases
    var sharedSecret = ""
    
    // This is the In-App Purchase product list
    var inAppProductList = [SKProduct]()
    
    // The product being bought
    var activeProduct = SKProduct()
    
    /// The space allocated for the folder
    var spaceAllocated: Int = 1024 * 1024 * 1024
    
    /// Has the space been exceeed
    var spaceAllocatedExceeded = false
    
    /// The duration of the subscription = 30 days
    let subscriptionDuration: Int = 43200
    
    /// The user's first name
    var ownerFirstName: String? = nil
    
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
    
    /// Document download
    var buffer: NSMutableData = NSMutableData()
    var session: URLSession?
    var dataTask: URLSessionDataTask?
    var expectedContentLength = 0
    var downloadedDocumentFileName: String? = nil
    
    // MARK:- View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if currentUser != folderOwner {
            buySpaceButton.isEnabled = false
            buySpaceButton.isHidden = true
            spaceUsedLabel.text = "0 MB of files"
            
            if ownerFirstName != nil {
                /// Set the recipeint name in the title
                self.navigationItem.title = ownerFirstName! + "'s Files"
            }
        } else {
            /// Set the recipeint name in the title
            self.navigationItem.title = "My Files"
        }
        
        /// Style the button and label
        let spaceUsedLabelLayer: CALayer?  = spaceUsedLabel.layer
        spaceUsedLabelLayer!.cornerRadius = 2
        spaceUsedLabelLayer!.masksToBounds = true
        
        let buySpaceButtonLayer: CALayer?  = buySpaceButton.layer
        buySpaceButtonLayer!.cornerRadius = 4
        buySpaceButtonLayer!.masksToBounds = true
        
        /// Setting UIDocumentInteractionController delegate.
        documentInteractionController.delegate = self
        
        self.tableView.delegate = self
        manager = AWSUserFileManager.defaultUserFileManager()
        
        // Sets up the UIs.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(UserFilesViewController.showContentManagerActionOptions(_:)))
        
        // Sets up the date formatter.
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale.current
        
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        didLoadAllContents = false
        
        UserFilesPublicDirectoryName = "public/" + folderOwner!
        
        if let prefix = prefix {
            print("Prefix already initialized to \(prefix)")
        } else {
            self.prefix = "\(UserFilesPublicDirectoryName)/"
        }
        refreshContents()
        updateUserInterface()
        loadMoreContents()
        updateSpaceAllocation()
        
        // Add all the In-App Purchases - in this case, there is only one
        // - a non-renewable. From there, start the In-App Purchase system.
        if (SKPaymentQueue.canMakePayments()) {
            print("In-App Purchases loading...")
            let productID: NSSet = NSSet(objects: ApplicationConstants.commonalityInAppPurchasesID)
            let request: SKProductsRequest = SKProductsRequest(productIdentifiers: productID as! Set<String>)
            request.delegate = self
            request.start()
        } else {
            print("Please enable In-App Purchases.")
        }

        /// The progress code
        let circularPath = UIBezierPath(arcCenter: .zero, radius: 100, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        trackLayer.path = circularPath.cgPath
        
        trackLayer.strokeColor = UIColor.lightGray.cgColor
        trackLayer.lineWidth = 10
        trackLayer.fillColor = UIColor.white.cgColor
        trackLayer.lineCap = kCALineCapRound
        trackLayer.position = view.center
        
        view.layer.addSublayer(trackLayer)
        
        shapeLayer.path = circularPath.cgPath
        
        let lightGreeen = UIColor(red: 41.0/255.0, green: 169.0/255.0, blue: 158.0/255.0, alpha: 1.0)
        shapeLayer.strokeColor = lightGreeen.cgColor
        shapeLayer.lineWidth = 10
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineCap = kCALineCapRound
        shapeLayer.position = view.center
        
        shapeLayer.transform = CATransform3DMakeRotation(-CGFloat.pi / 2, 0, 0, 1)
        
        shapeLayer.strokeEnd = 0
        
        view.layer.addSublayer(shapeLayer)
        
        view.addSubview(percentageLabel)
        percentageLabel.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        percentageLabel.center = view.center
        
        let purplish = UIColor(red: 192.0/255.0, green: 30.0/255.0, blue: 201.0/255.0, alpha: 1.0)
        percentageLabel.textColor = purplish
        
        percentageLabel.isHidden = true
        trackLayer.isHidden = true
        shapeLayer.isHidden = true
    }
    
    // Animates circle
    fileprivate func animateCircle() {
        let basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        
        basicAnimation.toValue = 1
        
        basicAnimation.duration = 2
        
        basicAnimation.fillMode = kCAFillModeForwards
        basicAnimation.isRemovedOnCompletion = false
        
        shapeLayer.add(basicAnimation, forKey: "urSoBasic")
    }
    
    // Updates the UI
    fileprivate func updateUserInterface() {
        DispatchQueue.main.async {
            if let prefix = self.prefix {
                var pathText = "\(prefix)"
                var startFrom = prefix.startIndex
                var offset = 0
                let maxPathTextLength = 50
                
                if prefix.hasPrefix(self.UserFilesPublicDirectoryName) {
                    startFrom = self.UserFilesPublicDirectoryName.endIndex
                } else if prefix.hasPrefix(UserFilesPrivateDirectoryName) {
                    let userId = AWSIdentityManager.default().identityId!
                    startFrom = UserFilesPrivateDirectoryName.endIndex
                    offset = userId.characters.count + 1
                } else if prefix.hasPrefix(UserFilesProtectedDirectoryName) {
                    startFrom = UserFilesProtectedDirectoryName.endIndex
                } else if prefix.hasPrefix(UserFilesUploadsDirectoryName) {
                    startFrom = UserFilesUploadsDirectoryName.endIndex
                }
                
                startFrom = prefix.characters.index(startFrom, offsetBy: offset + 1)
                pathText = "\(prefix.substring(from: startFrom))"
                
                if pathText.characters.count > maxPathTextLength {
                    pathText = "...\(pathText.substring(from: pathText.characters.index(pathText.endIndex, offsetBy: -maxPathTextLength)))"
                }
                self.pathLabel.text = "\(pathText)"
            } else {
                self.pathLabel.text = "/"
            }
            
            self.tableView.reloadData()
        }
    }
    
    
    // MARK:- Content Manager user action methods
    
    @IBAction func changeDirectory(_ sender: UISegmentedControl) {
        manager = AWSUserFileManager.defaultUserFileManager()
        switch(sender.selectedSegmentIndex) {
        case 0: //Public Directory
            prefix = "\(UserFilesPublicDirectoryName)/"
            break
        case 1: //Protected Directory
            if AWSSignInManager.sharedInstance().isLoggedIn {
                let userId = AWSIdentityManager.default().identityId!
                prefix = "\(UserFilesProtectedDirectoryName)/\(userId)/";
            } else {
                prefix = "\(UserFilesProtectedDirectoryName)/";
            }
            break
        default:
            break
        }
        segmentedControlSelected = sender.selectedSegmentIndex
        contents = []
        loadMoreContents()
    }
    
    @objc func showContentManagerActionOptions(_ sender: AnyObject) {
        if currentUser == folderOwner {
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let uploadImageVideoObjectAction = UIAlertAction(title: "Upload Image or Video", style: .default, handler: {[unowned self](action: UIAlertAction) -> Void in
                if self.spaceAllocatedExceeded {
                    self.displayCommonalityGenericAlert("Storage Exceeded", userMessage: "Your allocated space has been exceeded. Tap the 'Buy Space' button to get additional storage.")
                } else {
                    self.showImagePicker()
                }
            })
            alertController.addAction(uploadImageVideoObjectAction)
            
            let uploadDocumentObjectAction = UIAlertAction(title: "Upload Document", style: .default, handler: {[unowned self](action: UIAlertAction) -> Void in
                if self.spaceAllocatedExceeded {
                    self.displayCommonalityGenericAlert("Storage Exceeded", userMessage: "Your allocated storage space has been exceeded. Tap the 'Buy Space' button to get additional storage.")
                } else {
                    self.showDocumentPicker()
                }
            })
            alertController.addAction(uploadDocumentObjectAction)
            
            let refreshAction = UIAlertAction(title: "Refresh", style: .default, handler: {[unowned self](action: UIAlertAction) -> Void in
                self.refreshContents()
                })
            alertController.addAction(refreshAction)
            
            let downloadObjectsAction = UIAlertAction(title: "Download Recent", style: .default, handler: {[unowned self](action: UIAlertAction) -> Void in
                self.downloadObjectsToFillCache()
                })
            alertController.addAction(downloadObjectsAction)
            
            let changeLimitAction = UIAlertAction(title: "Set Cache Size", style: .default, handler: {[unowned self](action: UIAlertAction) -> Void in
                self.showDiskLimitOptions()
                })
            alertController.addAction(changeLimitAction)
            
            let removeAllObjectsAction = UIAlertAction(title: "Clear Cache", style: .destructive, handler: {[unowned self](action: UIAlertAction) -> Void in
                self.manager.clearCache()
                self.updateUserInterface()
                })
            alertController.addAction(removeAllObjectsAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true, completion: nil)
        }
    }
    
    fileprivate func refreshContents() {
        marker = nil
        loadMoreContents()
    }
    
    fileprivate func loadMoreContents() {
        let uploadsDirectory = "\(UserFilesUploadsDirectoryName)/"
        if prefix == uploadsDirectory {
            updateUserInterface()
            return
        }
        manager.listAvailableContents(withPrefix: prefix, marker: marker) {[weak self] (contents: [AWSContent]?, nextMarker: String?, error: Error?) in
            guard let strongSelf = self else { return }
            if let error = error {
                strongSelf.showSimpleAlertWithTitle("Error", message: "Failed to load the list of contents.", cancelButtonTitle: "OK")
                print("Failed to load the list of contents. \(error)")
            }
            
            if let contents = contents, contents.count > 0 {
                /// This section counts the size of the contents
                /// after they get added
                var incrementalSpace: Int = 0
                strongSelf.contents = [AWSContent]()
                
                /// Loops throught the contents and counts size
                for content in contents {
                    if strongSelf.spaceAllocated > incrementalSpace {
                        if strongSelf.contents != nil {
                            strongSelf.contents!.append(content)
                        }
                        
                        incrementalSpace += Int(content.knownRemoteByteCount)
                    } else {
                        strongSelf.spaceAllocatedExceeded = true
                    }
                }
                
                if let nextMarker = nextMarker, !nextMarker.isEmpty {
                    strongSelf.didLoadAllContents = false
                } else {
                    strongSelf.didLoadAllContents = true
                    
                    /// Count the amount of space used and
                    /// Set the space used on the label
                    if strongSelf.contents != nil {
                        var spaceUsed: Int = 0
                        
                        for content in strongSelf.contents! {
                            spaceUsed += Int(content.knownRemoteByteCount)
                        }
                        
                        let spaceUsedString = spaceUsed.commonalityStringFromByteCount()
                        strongSelf.spaceUsedLabel.text = spaceUsedString + " of \(strongSelf.spaceAllocated.commonalityStringFromByteCount()) used"
                        
                        if strongSelf.currentUser != strongSelf.folderOwner {
                            let spaceUsedString = spaceUsed.commonalityStringFromByteCount()
                            strongSelf.spaceUsedLabel.text = spaceUsedString + " of files"
                        }
                    }
                }
                strongSelf.marker = nextMarker
            } else {
                strongSelf.checkUserProtectedFolder()
            }
            strongSelf.updateUserInterface()
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    fileprivate func showDiskLimitOptions() {
        let alertController = UIAlertController(title: "Disk Cache Size", message: nil, preferredStyle: .actionSheet)
        for number: Int in [1, 5, 20, 50, 100] {
            let byteLimitOptionAction = UIAlertAction(title: "\(number) MB", style: .default, handler: {[unowned self](action: UIAlertAction) -> Void in
                self.manager.maxCacheSize = UInt(number) * 1024 * 1024
                self.updateUserInterface()
                })
            alertController.addAction(byteLimitOptionAction)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func downloadObjectsToFillCache() {
        manager.listRecentContents(withPrefix: prefix) {[weak self] (contents: [AWSContent]?, error: Error?) in
            guard let strongSelf = self else { return }
            
            contents?.forEach({ (content: AWSContent) in
                if !content.isCached && !content.isDirectory {
                    strongSelf.downloadContent(content, pinOnCompletion: false)
                }
            })
        }
    }
    
    // MARK:- Content user action methods
    
    fileprivate func showActionOptionsForContent(_ rect: CGRect, content: AWSContent) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if alertController.popoverPresentationController != nil {
            alertController.popoverPresentationController?.sourceView = self.view
            alertController.popoverPresentationController?.sourceRect = CGRect(x: rect.midX, y: rect.midY, width: 1.0, height: 1.0)
        }
        if content.isCached {
            let openAction = UIAlertAction(title: "Open", style: .default, handler: {(action: UIAlertAction) -> Void in
                DispatchQueue.main.async {
                    self.openContent(content)
                }
            })
            alertController.addAction(openAction)
        }
        
        if content.isAudioVideo() || content.isImage() {
            // Allow opening of remote files natively or in browser based on their type.
            let openRemoteAction = UIAlertAction(title: "Open Remote", style: .default, handler: {[unowned self](action: UIAlertAction) -> Void in
                self.openRemoteContent(content)
                
                })
            alertController.addAction(openRemoteAction)
        }
        
        // If the content hasn't been downloaded, and it's larger than the limit of the cache,
        // we don't allow downloading the contentn.
        if content.knownRemoteByteCount + 4 * 1024 < self.manager.maxCacheSize {
            // 4 KB is for local metadata.
            var title = "Download"
            
            if let downloadedDate = content.downloadedDate, let knownRemoteLastModifiedDate = content.knownRemoteLastModifiedDate, knownRemoteLastModifiedDate.compare(downloadedDate) == .orderedDescending {
                title = "Download Latest Version"
            }
            let downloadAction = UIAlertAction(title: title, style: .default, handler: {[unowned self](action: UIAlertAction) -> Void in
                self.downloadContent(content, pinOnCompletion: false)
                })
            alertController.addAction(downloadAction)
        }
        let downloadAndPinAction = UIAlertAction(title: "Download & Pin", style: .default, handler: {[unowned self](action: UIAlertAction) -> Void in
            self.downloadContent(content, pinOnCompletion: true)
            })
        alertController.addAction(downloadAndPinAction)
        if content.isCached {
            if content.isPinned {
                let unpinAction = UIAlertAction(title: "Unpin", style: .default, handler: {[unowned self](action: UIAlertAction) -> Void in
                    content.unPin()
                    self.updateUserInterface()
                    })
                alertController.addAction(unpinAction)
            } else {
                let pinAction = UIAlertAction(title: "Pin", style: .default, handler: {[unowned self](action: UIAlertAction) -> Void in
                    content.pin()
                    self.updateUserInterface()
                    })
                alertController.addAction(pinAction)
            }
            
            if currentUser == folderOwner {
                let removeAction = UIAlertAction(title: "Delete Local Copy", style: .destructive, handler: {[unowned self](action: UIAlertAction) -> Void in
                    content.removeLocal()
                    self.updateUserInterface()
                    })
                alertController.addAction(removeAction)
            }
        }
        
        if currentUser == folderOwner {
            let removeFromRemoteAction = UIAlertAction(title: "Delete Remote File", style: .destructive, handler: {[unowned self](action: UIAlertAction) -> Void in
                self.confirmForRemovingContent(content)
                })
            
            alertController.addAction(removeFromRemoteAction)
        }
        
        if currentUser != folderOwner {
            let reportFileAction = UIAlertAction(title: "Report File", style: .destructive, handler: {[unowned self](action: UIAlertAction) -> Void in
                self.reportAbuse(fileName: content.key)
            })
            
            alertController.addAction(reportFileAction)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func downloadContent(_ content: AWSContent, pinOnCompletion: Bool) {
        shapeLayer.strokeEnd = 0
        percentageLabel.text = "0%"
        
        if !content.isAudioVideo() && !content.isImage() {
            content.getRemoteFileURL { (url, error) in
                self.downloadedDocumentFileName = nil
                
                let cells = self.tableView.visibleCells
                
                if cells.count > 3 {
                    let centerNumber = cells.count / 2
                    let cell = cells[centerNumber]
                    
                    self.trackLayer.position = cell.center
                    self.shapeLayer.position = cell.center
                    self.percentageLabel.center = cell.center
                }
                
                self.percentageLabel.isHidden = false
                self.trackLayer.isHidden = false
                self.shapeLayer.isHidden = false
                
                guard let url = URL(string: (url?.absoluteString)!) else { return }
                
                var displayFilename: String = content.key
                if let prefix = self.prefix {
                    if displayFilename.characters.count > prefix.characters.count {
                        displayFilename = displayFilename.substring(from: prefix.endIndex)
                    }
                }
                
                self.downloadedDocumentFileName = displayFilename
                
                let configuration = URLSessionConfiguration.default
                let manqueue = OperationQueue.main
                self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: manqueue)
                
                self.dataTask = self.session?.dataTask(with: NSURLRequest(url: url) as URLRequest)
                self.dataTask?.resume()
            }
        } else {
            let cells = self.tableView.visibleCells
            
            if cells.count > 3 {
                let centerNumber = cells.count / 2
                let cell = cells[centerNumber]
                
                self.trackLayer.position = cell.center
                self.shapeLayer.position = cell.center
                self.percentageLabel.center = cell.center
            }
            
            percentageLabel.isHidden = false
            trackLayer.isHidden = false
            shapeLayer.isHidden = false
            
            content.download(with: .ifNewerExists, pinOnCompletion: pinOnCompletion, progressBlock: {[weak self] (content: AWSContent, progress: Progress) in
                guard let strongSelf = self else { return }
                if strongSelf.contents!.contains( where: {$0 == content} ) {
                    strongSelf.tableView.reloadData()
                }
                
                /// Animate the progress
                print("\(progress.fractionCompleted)")
                strongSelf.percentageLabel.text = "\(Int(progress.fractionCompleted * 100))%"
                strongSelf.shapeLayer.strokeEnd = CGFloat(progress.fractionCompleted)
            }) {[weak self] (content: AWSContent?, data: Data?, error: Error?) in
                guard let strongSelf = self else { return }
                
                strongSelf.percentageLabel.isHidden = true
                strongSelf.trackLayer.isHidden = true
                strongSelf.shapeLayer.isHidden = true
                
                if let error = error {
                    print("Failed to download a content from a server. \(error)")
                    strongSelf.showSimpleAlertWithTitle("Error", message: "Failed to download a content from a server.", cancelButtonTitle: "OK")
                } else {
                    if data != nil {
                        if strongSelf.currentUser != nil && strongSelf.folderOwner != nil {
                            if (content?.isImage())! {
                                let image = UIImage(data: data!)
                                UIImageWriteToSavedPhotosAlbum(image!, self, #selector(self?.image(_:didFinishSavingWithError:contextInfo:)), nil)
                                
                                /// Record the download in the dBase
                                strongSelf.saveDownload(fileName: (content?.key)!, user: strongSelf.currentUser!, folderOwner: strongSelf.folderOwner!)
                            } else if (content?.isAudioVideo())!{
                                // If the file is a video
                                let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
                                let documentDirectoryURL = URL(fileURLWithPath: documentDirectory)
                                
                                let fullRemotePath = (content?.key)!
                                let fullRemotePathArray = fullRemotePath.components(separatedBy: "/")
                                
                                let fileName = fullRemotePathArray[2]
                                
                                let downloadFileURL = documentDirectoryURL.appendingPathComponent(fileName)
                                
                                do {
                                    try data?.write(to: downloadFileURL)
                                    
                                    if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(downloadFileURL.relativePath) {
                                        UISaveVideoAtPathToSavedPhotosAlbum(downloadFileURL.relativePath, nil, nil, nil)
                                        
                                        strongSelf.saveDownload(fileName: (content?.key)!, user: strongSelf.currentUser!, folderOwner: strongSelf.folderOwner!)
                                        
                                        let ac = UIAlertController(title: "Saved", message: "Your file has been saved.", preferredStyle: .alert)
                                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                                        strongSelf.present(ac, animated: true)
                                    }
                                } catch {
                                    // Do nothing
                                }
                            } else {
                                
                            }
                        }
                    }
                }
                strongSelf.updateUserInterface()
            }
        }
    }
    
    fileprivate func openContent(_ content: AWSContent) {
        if content.isAudioVideo() { // Video and sound files
            let directories: [AnyObject] = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true) as [AnyObject]
            let cacheDirectoryPath = directories.first as! String
            
            let movieURL: URL = URL(fileURLWithPath: "\(cacheDirectoryPath)/\(content.key.getLastPathComponent())")
            
            try? content.cachedData.write(to: movieURL, options: [.atomic])
            
            let player = AVPlayer(url: movieURL)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            self.present(playerViewController, animated: true) {
                playerViewController.player!.play()
            }
        } else if content.isImage() { // Image files
            // Image files
            let storyboard = UIStoryboard(name: UserFilesStoryBoard, bundle: nil)
            let imageViewController = storyboard.instantiateViewController(withIdentifier: "UserFilesImageViewController") as! UserFilesImageViewController
            imageViewController.image = UIImage(data: content.cachedData)
            imageViewController.title = content.key
            navigationController?.pushViewController(imageViewController, animated: true)
        } else {
            showSimpleAlertWithTitle("Sorry!", message: "We can only open image, video, and sound files.", cancelButtonTitle: "OK")
        }
    }
    
    fileprivate func openRemoteContent(_ content: AWSContent) {
        content.getRemoteFileURL {[weak self] (url: URL?, error: Error?) in
            guard let strongSelf = self else { return }
            guard let url = url else {
                print("Error getting URL for file. \(error)")
                return
            }
            if content.isAudioVideo() { // Open Audio and Video files natively in app.
                let player = AVPlayer(url: url)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                strongSelf.present(playerViewController, animated: true) {
                    playerViewController.player!.play()
                }
            } else { // Open other file types like PDF in web browser.
                //UIApplication.sharedApplication().openURL(url)
                let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let webViewController: UserFilesWebViewController = storyboard.instantiateViewController(withIdentifier: "UserFilesWebViewController") as! UserFilesWebViewController
                webViewController.url = url
                webViewController.title = content.key
                strongSelf.navigationController?.pushViewController(webViewController, animated: true)
            }
        }
    }
    
    fileprivate func confirmForRemovingContent(_ content: AWSContent) {
        let alertController = UIAlertController(title: "Confirm", message: "Do you want to delete the content from the server? This cannot be undone.", preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Yes", style: .default) {[weak self] (action: UIAlertAction) in
            guard let strongSelf = self else { return }
            strongSelf.removeContent(content)
        }
        alertController.addAction(okayAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func removeContent(_ content: AWSContent) {
        content.removeRemoteContent {[weak self] (content: AWSContent?, error: Error?) in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to delete an object from the remote server. \(error)")
                    strongSelf.showSimpleAlertWithTitle("Error", message: "Failed to delete an object from the remote server.", cancelButtonTitle: "OK")
                } else {
                    strongSelf.showSimpleAlertWithTitle("Object Deleted", message: "The object has been deleted successfully.", cancelButtonTitle: "OK")
                    strongSelf.refreshContents()
                }
            }
        }
    }
    
    // MARK:- Content uploads
    
    fileprivate func showImagePicker() {
        let imagePickerController: UIImagePickerController = UIImagePickerController()
        imagePickerController.mediaTypes =  [kUTTypeImage as String, kUTTypeMovie as String]
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    fileprivate func showDocumentPicker() {
        let importMenu = UIDocumentPickerViewController(documentTypes: [String(kUTTypePDF), String(kUTTypePlainText), String(kUTTypeMP3), String(kUTTypeRTF), String(kUTTypeZipArchive), String(kUTTypeBzip2Archive), String(kUTTypeGNUZipArchive), String(kUTTypeGIF), String(kUTTypeTIFF), String(kUTTypeExecutable)], in: .import)
        
        importMenu.delegate = self
        importMenu.modalPresentationStyle = .formSheet
        present(importMenu, animated: true, completion: nil)
    }
    
    fileprivate func askForFilename(_ data: Data, fileExtension: String?, fileName: String?) {
        if fileName == nil  {
            let alertController = UIAlertController(title: "File Name", message: "Please specify the file name.", preferredStyle: .alert)
            alertController.addTextField(configurationHandler: nil)
            let doneAction = UIAlertAction(title: "Done", style: .default) {[unowned self] (action: UIAlertAction) in
                let specifiedKey = alertController.textFields!.first!.text!
                if specifiedKey.characters.count == 0 {
                    self.showSimpleAlertWithTitle("Error", message: "The file name cannot be empty.", cancelButtonTitle: "OK")
                    return
                } else {
                    let key: String = "\(self.prefix!)\(specifiedKey)" + "." + fileExtension!
                    self.uploadWithData(data, forKey: key)
                }
            }
            alertController.addAction(doneAction)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        } else {
            let key: String = "\(self.prefix!)\(fileName)"
            self.uploadWithData(data, forKey: key)
        }
    }
    
    fileprivate func askForDirectoryName() {
        let alertController: UIAlertController = UIAlertController(title: "Directory Name", message: "Please specify the directory name.", preferredStyle: .alert)
        alertController.addTextField(configurationHandler: nil)
        let doneAction = UIAlertAction(title: "Done", style: .default) {[unowned self] (action: UIAlertAction) in
            let specifiedKey = alertController.textFields!.first!.text!
            guard specifiedKey.characters.count != 0 else {
                self.showSimpleAlertWithTitle("Error", message: "The directory name cannot be empty.", cancelButtonTitle: "OK")
                return
            }
            
            let key = "\(self.prefix!)\(specifiedKey)/"
            self.createFolderForKey(key)
        }
        alertController.addAction(doneAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func uploadLocalContent(_ localContent: AWSLocalContent) {
        shapeLayer.strokeEnd = 0
        percentageLabel.text = "0%"
        
        let cells = self.tableView.visibleCells
        
        if cells.count > 3 {
            let centerNumber = cells.count / 2
            let cell = cells[centerNumber]
            
            self.trackLayer.position = cell.center
            self.shapeLayer.position = cell.center
            self.percentageLabel.center = cell.center
        }
        
        percentageLabel.isHidden = false
        trackLayer.isHidden = false
        shapeLayer.isHidden = false
        
        localContent.uploadWithPin(onCompletion: false, progressBlock: {[weak self] (content: AWSLocalContent, progress: Progress) in
            guard let strongSelf = self else { return }
            
            /// Animate the progress thing
            print("\(progress.fractionCompleted)")
            strongSelf.percentageLabel.text = "\(Int(progress.fractionCompleted * 100))%"
            strongSelf.shapeLayer.strokeEnd = CGFloat(progress.fractionCompleted)
            
            DispatchQueue.main.async {
                // Update the upload UI if it is a new upload and the table is not yet updated
                if(strongSelf.tableView.numberOfRows(inSection: 0) == 0 || strongSelf.tableView.numberOfRows(inSection: 0) < strongSelf.manager.uploadingContents.count) {
                    strongSelf.updateUploadUI()
                } else {
                    strongSelf.tableView.reloadData()
                }
            }
            }, completionHandler: {[weak self] (content: AWSLocalContent?, error: Error?) in
                guard let strongSelf = self else { return }
                
                strongSelf.percentageLabel.isHidden = true
                strongSelf.trackLayer.isHidden = true
                strongSelf.shapeLayer.isHidden = true
                
                strongSelf.updateUploadUI()
                strongSelf.saveUpload(fileName: localContent.key, user: strongSelf.currentUser, folderOwner: strongSelf.folderOwner)
                if let error = error {
                    print("Failed to upload an object. \(error)")
                    strongSelf.showSimpleAlertWithTitle("Error", message: "Failed to upload an object.", cancelButtonTitle: "OK")
                } else {
                    if localContent.key.hasPrefix(UserFilesUploadsDirectoryName) {
                        strongSelf.showSimpleAlertWithTitle("File upload", message: "File upload completed successfully for \(localContent.key).", cancelButtonTitle: "Okay")
                    }
                    strongSelf.refreshContents()
                }
        })
        updateUploadUI()
    }
    
    fileprivate func uploadWithData(_ data: Data, forKey key: String) {
        let localContent = manager.localContent(with: data, key: key)
        uploadLocalContent(localContent)
    }
    
    fileprivate func createFolderForKey(_ key: String) {
        let localContent = manager.localContent(with: nil, key: key)
        uploadLocalContent(localContent)
    }
    
    fileprivate func updateUploadUI() {
        DispatchQueue.main.async {
            self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return manager.uploadingContents.count
        }
        if let contents = self.contents {
            if isPrefixUploadsFolder() { // Uploads folder is write-only and table view show only one cell with that info
                return 1
            } else if isPrefixUserProtectedFolder() { // the first cell of the table view is the .. folder
                return contents.count + 1
            } else {
                return contents.count
            }
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UserFilesUploadCell", for: indexPath) as! UserFilesUploadCell
            if indexPath.row < manager.uploadingContents.count {
                let localContent: AWSLocalContent = manager.uploadingContents[indexPath.row]
                cell.localContent = localContent
            }
            cell.prefix = prefix
            
            return cell
        }
        
        let cell: UserFilesCell = tableView.dequeueReusableCell(withIdentifier: "UserFilesCell", for: indexPath) as! UserFilesCell
        
        var content: AWSContent? = nil
        if isPrefixUserProtectedFolder() {
            if indexPath.row > 0 && indexPath.row < contents!.count + 1 {
                content = contents![indexPath.row - 1]
            }
        } else {
            if indexPath.row < contents!.count {
                content = contents![indexPath.row]
            }
        }
        cell.prefix = prefix
        cell.content = content
        
        if isPrefixUserProtectedFolder() && indexPath.row == 0 {
            cell.fileNameLabel.text = ".."
            cell.accessoryType = .disclosureIndicator
            cell.detailLabel.text = "This is a folder"
        } else if isPrefixUploadsFolder() {
            cell.fileNameLabel.text = "This folder is write only"
            cell.accessoryType = .disclosureIndicator
            cell.detailLabel.text = ""
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let contents = self.contents, indexPath.row == contents.count - 1, !didLoadAllContents {
            loadMoreContents()
        }
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Process only if it is a listed file. Ignore actions for files that are uploading.
        if indexPath.section != 0 {
            var content: AWSContent?
            
            if isPrefixUploadsFolder() {
                showImagePicker()
                return
            } else if !isPrefixUserProtectedFolder() {
                content = contents![indexPath.row]
            } else {
                if indexPath.row > 0 {
                    content = contents![indexPath.row - 1]
                } else {
                    let storyboard: UIStoryboard = UIStoryboard(name: UserFilesStoryBoard, bundle: nil)
                    let viewController: UserFilesViewController = storyboard.instantiateViewController(withIdentifier: "UserFiles") as! UserFilesViewController
                    viewController.prefix = "\(UserFilesProtectedDirectoryName)/"
                    viewController.segmentedControlSelected = self.segmentedControlSelected
                    navigationController?.pushViewController(viewController, animated: true)
                    return
                }
            }
            if content!.isDirectory {
                let storyboard: UIStoryboard = UIStoryboard(name: UserFilesStoryBoard, bundle: nil)
                let viewController: UserFilesViewController = storyboard.instantiateViewController(withIdentifier: "UserFiles") as! UserFilesViewController
                viewController.prefix = content!.key
                viewController.segmentedControlSelected = self.segmentedControlSelected
                navigationController?.pushViewController(viewController, animated: true)
            } else {
                let rowRect = tableView.rectForRow(at: indexPath);
                showActionOptionsForContent(rowRect, content: content!)
            }
        }
    }
    
    // Record the upload
    func saveUpload(fileName: String, user: String?, folderOwner: String?) {
        print("Inside saving 1.")
        /// Check that there aren't any nils
        if user != nil && folderOwner != nil {
            print("Inside saving 1.")
            let fileData = [
                "folderOwner": folderOwner!,
                "fileName": fileName
                ] as [String : Any]
            
            let dBase = Firestore.firestore()
            let fileRef = dBase.collection("files").document(user!)
            fileRef.collection("uploads").addDocument(data: fileData)
            print("Inside saving 1.")
        }
    }
    
    // Record the download
    func saveDownload(fileName: String, user: String?, folderOwner: String?) {
        /// Check that there aren't any nils
        if user != nil && folderOwner != nil {
            let fileData = [
                "folderOwner": folderOwner!,
                "fileName": fileName
                ] as [String : Any]
            
            let dBase = Firestore.firestore()
            let fileRef = dBase.collection("files").document(user!)
            fileRef.collection("downloads").addDocument(data: fileData)
        }
    }
    
    // Saving alert
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved", message: "Your file has been saved.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
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
     This reports user abuse.
     
     - Parameters:
     - fileName: The abusive file name
     
     - Returns: void.
     */
    func reportAbuse(fileName: String) {
        let alert = UIAlertController(title: "Report offensive/inappropriate content", message: "You may report this file if you find its content offfensive or inappropriate.  It will then be reviewed by the Commonality team.  Reporting is anonymous. Would you like to continue with your report?", preferredStyle: UIAlertControllerStyle.alert)
        
        // add the actions (buttons)
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { (alert) -> Void in
            self.sendReport(fileName: fileName)
        }))
        alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: nil))
        
        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    /**
     Sends a report to the backend.
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func sendReport(fileName: String) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let currentDate = Date()
        let timeStamp = Int(currentDate.timeIntervalSince1970)
        
        let reportData = [
            "fileName": fileName,
            "creationAt": timeStamp,
            "dealtWith": false
            ] as [String : Any]
        
        let dBase = Firestore.firestore()
        dBase.collection("report").addDocument(data: reportData) { (error) in
            if error == nil {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                self.displayCommonalityGenericAlert("Reporting successful", userMessage: "You have successfully reported the file. The Majesho team will review it.")
            }
        }
    }
    
    // Suscribes the user after payment
    func subscribeForNineExtraGigs() {
        if currentUser != nil {
            let currentDate = Date()
            let timeStamp = Int(currentDate.timeIntervalSince1970)
            
            let subscriptionData = [
                "creationAt": timeStamp,
                "dealtWith": false
                ] as [String : Any]
            
            let dBase = Firestore.firestore()
            dBase.collection("subscriptions").document(currentUser!).collection(ApplicationConstants.commonalityInAppPurchasesID).addDocument(data: subscriptionData) { (error) in
                if error == nil {
                    self.updateSpaceAllocation()
                    self.displayCommonalityGenericAlert("Congratulations!", userMessage: "You have successfully subscribed for 9 extra gigs for a period of 30 days.")
                }
            }
        }
    }
    
    /// MARK - The In-App Purchase section
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("Product request")
        let products = response.products
        for product in products {
            print("Product added")
            print(product.productIdentifier)
            print(product.localizedTitle)
            print(product.localizedDescription)
            print(product.price)
            
            inAppProductList.append(product)
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        print("Transactions restored")
        for transaction in queue.transactions {
            let t: SKPaymentTransaction = transaction
            let prodID = t.payment.productIdentifier as String
            
            switch prodID {
            case ApplicationConstants.commonalityInAppPurchasesID:
                print("Subscribe for ten extra spaces.")
                subscribeForNineExtraGigs()
            default:
                print("In-App Purchase not found.")
            }
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("Add payment")
        
        for transaction: AnyObject in transactions {
            let trans = transaction as! SKPaymentTransaction
            
            switch trans.transactionState {
            case .purchased:
                print("Buy OK, unlock In-App Purchase here.")
                print(activeProduct.productIdentifier)
                
                let prodID = activeProduct.productIdentifier
                
                switch prodID {
                case ApplicationConstants.commonalityInAppPurchasesID:
                    print("Subscribe for 9 extra gigs.")
                    subscribeForNineExtraGigs()
                default:
                    print("In-App Purchase not found.")
                }
                queue.finishTransaction(trans)
                break
            case .failed:
                print("Buy error.")
                displayCommonalityGenericAlert("Purchasing issue", userMessage: "There seems to have been an issue with your in-app purchase. Please try again later.")
                queue.finishTransaction(trans)
                break
            default:
                print("Default")
                break
            }
        }
    }
    
    func buyProduct() {
        print("Buy " + activeProduct.productIdentifier)
        let pay = SKPayment(product: activeProduct)
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().add(pay as SKPayment)
    }
    
    // The buy space button action
    @IBAction func buySpaceButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Extra space: Buy 9 more gigs", message: "Store more files in your Commonality folder. Buy 9 more gigabytes of storage for 30 days. Tap 'Buy 9 more gigs' to continue.", preferredStyle: UIAlertControllerStyle.alert)
        
        // add the actions (buttons)
        alert.addAction(UIAlertAction(title: "Buy 9 more gigs", style: UIAlertActionStyle.default, handler: { (alert) -> Void in
            for product in self.inAppProductList {
                let productID = product.productIdentifier
                if (productID == ApplicationConstants.commonalityInAppPurchasesID) {
                    self.activeProduct = product
                    self.buyProduct()
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: { (alert) -> Void in
            //self.createSpreebieBarButtonItem.isEnabled = true
        }))
        
        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        //here you can get full lenth of your content
        expectedContentLength = Int(response.expectedContentLength)
        print(expectedContentLength)
        completionHandler(URLSession.ResponseDisposition.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data as Data)
        
        let percentageDownloaded = Float(buffer.length) / Float(expectedContentLength)
        print("Percentage is: \(percentageDownloaded)")
        percentageLabel.text = "\(Int(percentageDownloaded * 100))%"
        shapeLayer.strokeEnd = CGFloat(percentageDownloaded)
        //progress.progress =  percentageDownloaded
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        percentageLabel.isHidden = true
        trackLayer.isHidden = true
        shapeLayer.isHidden = true
        
        if downloadedDocumentFileName != nil {
            let data = NSData(data: buffer as Data)
            let tmpURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(downloadedDocumentFileName! ?? "fileName.png")
            do {
                try data.write(to: tmpURL)
            } catch {
                print(error)
            }
            
            DispatchQueue.main.async {
                self.share(url: tmpURL)
            }
        }
    }
    
    // Update the space allocation if user has an current subscriptions
    func updateSpaceAllocation() {
        /// Check for nil
        if currentUser != nil {
            let dBase = Firestore.firestore()
            let subscriptionRef = dBase.collection("subscriptions").document(currentUser!).collection("Commonality9GigsFor30Days")
            
            subscriptionRef.getDocuments { (querySnapshot, error) in
                if error == nil {
                    if let queryDocumentSnapshot = querySnapshot?.documents {
                        for data in queryDocumentSnapshot {
                            let subscriptionDict = data.data()
                            
                            if let creationAtTimeStamp = subscriptionDict["creationAt"] as? Int {
                                let currentDate = Date()
                                let creationAt = Date(timeIntervalSince1970: TimeInterval(creationAtTimeStamp))
                                
                                let minuteDifference: Double = currentDate.timeIntervalSince(creationAt) / 60.0
                                let minuteDifferenceInt = Int(minuteDifference)
                                
                                let timeLeftOnSubscription: Int = self.subscriptionDuration - minuteDifferenceInt
                                
                                if timeLeftOnSubscription > 0 {
                                    self.buySpaceButton.isEnabled = false
                                    self.spaceAllocated = 10 * 1024 * 1024 * 1024;
                                    
                                    self.refreshContents()
                                } else {
                                    self.buySpaceButton.isEnabled = true
                                    self.spaceAllocated = 1024 * 1024 * 1024;
                                    
                                    self.refreshContents()
                                }
                                
                                if timeLeftOnSubscription <= 4319 && timeLeftOnSubscription > 0 {
                                    if self.currentUser == self.folderOwner {
                                        self.displayCommonalityGenericAlert("Subscription info", userMessage: "You subscription for '9 More Gigs For 30 Days' will expire in less than 3 days.")
                                    }
                                }
                                
                                if timeLeftOnSubscription > 0 {
                                    break
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}


extension UserFilesViewController {
    /// This function will set all the required properties, and then provide a preview for the document
    func share(url: URL) {
        documentInteractionController.url = url
        documentInteractionController.uti = url.typeIdentifier ?? "public.data, public.content"
        documentInteractionController.name = url.localizedName ?? url.lastPathComponent
        documentInteractionController.presentPreview(animated: true)
    }
}

// MARK:- UIImagePickerControllerDelegate

extension UserFilesViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentMenuDelegate, UIDocumentPickerDelegate, UIDocumentInteractionControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        dismiss(animated: true, completion: nil)
        
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        // Handle image uploads
        if mediaType.isEqual(to: kUTTypeImage as String) {
            let image: UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
            
            askForFilename(UIImagePNGRepresentation(image)!, fileExtension: "png", fileName: nil)
        }
        // Handle Video Uploads
        if mediaType.isEqual(to: kUTTypeMovie as String) {
            let videoURL: URL = info[UIImagePickerControllerMediaURL] as! URL
            let fileExtension = videoURL.pathExtension
            
            askForFilename(try! Data(contentsOf: videoURL), fileExtension: fileExtension, fileName: nil)
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        /// Handle your document
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                let fileExtension = url.pathExtension
                
                askForFilename(try! Data(contentsOf: url), fileExtension: fileExtension, fileName: nil)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .overCurrentContext
        present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        /// Picker was cancelled! Duh 🤷🏻‍♀️
    }
    
    /// If presenting atop a navigation stack, provide the navigation controller in order to animate in a manner consistent with the rest of the platform
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        guard let navVC = self.navigationController else {
            return self
        }
        return navVC
    }
}

extension URL {
    var typeIdentifier: String? {
        return (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier
    }
    var localizedName: String? {
        return (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName
    }
}

class UserFilesCell: UITableViewCell {
    
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var keepImageView: UIImageView!
    @IBOutlet weak var downloadedImageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var fileIcon: UIImageView!
    
    var prefix: String?
    
    var content: AWSContent! {
        didSet {
            if self.content == nil {
                fileNameLabel.text = ""
                downloadedImageView.isHidden = true
                keepImageView.isHidden = true
                detailLabel.text = ""
                accessoryType = .disclosureIndicator
                progressView.isHidden = true
                detailLabel.textColor = UIColor.black
                return
            }
            var displayFilename: String = self.content.key
            if let prefix = self.prefix {
                if displayFilename.characters.count > prefix.characters.count {
                    displayFilename = displayFilename.substring(from: prefix.endIndex)
                }
            }
            fileNameLabel.text = displayFilename
            
            if !content.isImage() && !content.isAudioVideo() {
                fileIcon.image = #imageLiteral(resourceName: "document_icon")
            } else {
                fileIcon.image = #imageLiteral(resourceName: "media_icon")
            }
            
            downloadedImageView.isHidden = !content.isCached
            keepImageView.isHidden = !content.isPinned
            var contentByteCount: UInt = content.fileSize
            if contentByteCount == 0 {
                contentByteCount = content.knownRemoteByteCount
            }
            
            if content.isDirectory {
                detailLabel.text = "This is a folder"
                accessoryType = .disclosureIndicator
            } else {
                detailLabel.text = contentByteCount.aws_stringFromByteCount()
                accessoryType = .none
            }
            
            if let downloadedDate = content.downloadedDate, let knownRemoteLastModifiedDate = content.knownRemoteLastModifiedDate, knownRemoteLastModifiedDate.compare(downloadedDate) == .orderedDescending {
                detailLabel.text = "\(detailLabel.text!) - New Version Available"
                detailLabel.textColor = UIColor.blue
            } else {
                detailLabel.textColor = UIColor.black
            }
            
            if content.status == .running {
                progressView.progress = Float(content.progress.fractionCompleted)
                progressView.isHidden = false
            } else {
                progressView.isHidden = true
            }
        }
    }
}

class UserFilesImageViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    var image: UIImage!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        imageView.image = image
    }
}

class UserFilesWebViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    var url: URL!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        webView.delegate = self
        webView.dataDetectorTypes = UIDataDetectorTypes()
        webView.scalesPageToFit = true
        webView.loadRequest(URLRequest(url: url))
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        print("The URL content failed to load \(error)")
        webView.loadHTMLString("<html><body><h1>Cannot Open the content of the URL.</h1></body></html>", baseURL: nil)
    }
}

class UserFilesUploadCell: UITableViewCell {
    
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    var prefix: String?
    
    var localContent: AWSLocalContent! {
        didSet {
            var displayFilename: String = localContent.key
            if self.prefix != nil && displayFilename.hasPrefix(self.prefix!) {
                displayFilename = displayFilename.substring(from: self.prefix!.endIndex)
            }
            fileNameLabel.text = displayFilename
            progressView.progress = Float(localContent.progress.fractionCompleted)
        }
    }
}

// MARK: - Utility

extension UserFilesViewController {
    fileprivate func showSimpleAlertWithTitle(_ title: String, message: String, cancelButtonTitle cancelTitle: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func checkUserProtectedFolder() {
        let userId = AWSIdentityManager.default().identityId!
        if isPrefixUserProtectedFolder() {
            let localContent = self.manager.localContent(with: nil, key: "\(UserFilesProtectedDirectoryName)/\(userId)/")
            localContent.uploadWithPin(onCompletion: false, progressBlock: {(content: AWSLocalContent?, progress: Progress?) in
            }, completionHandler: {[weak self](content: AWSContent?, error: Error?) in
                guard let strongSelf = self else { return }
                strongSelf.updateUploadUI()
                if let error = error {
                    print("Failed to load the list of contents. \(error)")
                    strongSelf.showSimpleAlertWithTitle("Error", message: "Failed to load the list of contents.", cancelButtonTitle: "OK")
                }
                strongSelf.updateUserInterface()
            })
        }
    }
    
    fileprivate func isPrefixUserProtectedFolder() -> Bool {
        let userId = AWSIdentityManager.default().identityId!
        let protectedUserDirectory = "\(UserFilesProtectedDirectoryName)/\(userId)/"
        return AWSSignInManager.sharedInstance().isLoggedIn && protectedUserDirectory == prefix
    }
    
    fileprivate func isPrefixUploadsFolder() -> Bool {
        let uploadsDirectory = "\(UserFilesUploadsDirectoryName)/"
        return uploadsDirectory == prefix
    }
}

extension AWSContent {
    fileprivate func isAudioVideo() -> Bool {
        let lowerCaseKey = self.key.lowercased()
        return lowerCaseKey.hasSuffix(".mov")
            || lowerCaseKey.hasSuffix(".mp4")
            || lowerCaseKey.hasSuffix(".mpv")
            || lowerCaseKey.hasSuffix(".3gp")
            || lowerCaseKey.hasSuffix(".mpeg")
            || lowerCaseKey.hasSuffix(".aac")
            || lowerCaseKey.hasSuffix(".mp3")
    }
    
    fileprivate func isImage() -> Bool {
        let lowerCaseKey = self.key.lowercased()
        return lowerCaseKey.hasSuffix(".jpg")
            || lowerCaseKey.hasSuffix(".png")
            || lowerCaseKey.hasSuffix(".jpeg")
    }
}

extension UInt {
    fileprivate func aws_stringFromByteCount() -> String {
        if self < 1024 {
            return "\(self) B"
        }
        if self < 1024 * 1024 {
            return "\(self / 1024) KB"
        }
        if self < 1024 * 1024 * 1024 {
            return "\(self / 1024 / 1024) MB"
        }
        return "\(self / 1024 / 1024 / 1024) GB"
    }
}

extension Int {
    fileprivate func commonalityStringFromByteCount() -> String {
        if self < 1024 {
            return "\(self) B"
        }
        if self < 1024 * 1024 {
            return "\(self / 1024) KB"
        }
        if self < 1024 * 1024 * 1024 {
            return "\(self / 1024 / 1024) MB"
        }
        return "\(self / 1024 / 1024 / 1024) GB"
    }
}

extension String {
    fileprivate func getLastPathComponent() -> String {
        let nsstringValue: NSString = self as NSString
        return nsstringValue.lastPathComponent
    }
}
