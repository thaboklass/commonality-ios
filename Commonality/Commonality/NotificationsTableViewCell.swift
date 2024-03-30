//
//  NotificationsTableViewCell.swift
//  Commonality
//
//  Created by Thabo David Klass on 31/3/18.
//  Copyright © 2018 Spreebie, Inc. All rights reserved.
//

import UIKit
import FirebaseFirestore
// The notifications table view cell
class NotificationsTableViewCell: UITableViewCell {
    // The outlets
    @IBOutlet weak var notificationSenderProfilePicImageView: UIImageView!
    @IBOutlet weak var nameButton: UIButton!
    @IBOutlet weak var notificationTextLabel: UILabel!
    @IBOutlet weak var yesButton: UIButton!
    @IBOutlet weak var noButton: UIButton!
    @IBOutlet weak var notificationSenderActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var borderView: UIView!
    
    // These will be implemented on the Notifications view controller
    var onNameButtonTapped: (() -> Void)? = nil
    var onYesButtonTapped: (() -> Void)? = nil
    var onNoButtonTapped: (() -> Void)? = nil

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        /// Start the image view out as invisible
        notificationSenderProfilePicImageView.alpha = 0
        
        /// Create rounded corners
        let greenish = UIColor(red: 45.0/255.0, green: 182.0/255.0, blue: 174.0/255.0, alpha: 1.0)        
        
        let cellImageLayer: CALayer? = notificationSenderProfilePicImageView.layer
        cellImageLayer!.borderWidth = 2.0
        cellImageLayer!.borderColor = UIColor.white.cgColor
        
        cellImageLayer!.cornerRadius = notificationSenderProfilePicImageView.frame.height / 2 // 6
        //cellImageLayer!.cornerRadius = 8
        cellImageLayer!.masksToBounds = true
        
        let cellBorderLayer: CALayer? = borderView.layer
        cellBorderLayer!.borderWidth = 2.0
        cellBorderLayer!.borderColor = greenish.cgColor
        
        cellBorderLayer!.cornerRadius = borderView.frame.height / 2 //
        cellBorderLayer!.masksToBounds = true
    }
    
    // The name button action
    @IBAction func nameButtonTapped(_ sender: Any) {
        if let onNameButtonTapped = self.onNameButtonTapped {
            onNameButtonTapped()
        }
    }
    
    // The yes button action
    @IBAction func yesButtonTapped(_ sender: Any) {
        if let onYesButtonTapped = self.onYesButtonTapped {
            onYesButtonTapped()
        }
    }
    
    // The no button action
    @IBAction func noButtonTapped(_ sender: Any) {
        if let onNoButtonTapped = self.onNoButtonTapped {
            onNoButtonTapped()
        }
    }
    
    
    /**
     This is sets the profile picture
     
     - Parameters:
     - user: The user ID
     
     - Returns: void.
     */
    func setProfilePicture(user: String) {
        notificationSenderActivityIndicatorView.startAnimating()
        
        // Get firestore dBase
        let dBase = Firestore.firestore()
        
        let userRef = dBase.collection("users").document(user)
        
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let userDict = document.data() {
                    /// Check for nil again
                    if let username = userDict["fullName"] as? String, let userImage = userDict["profilePictureFileName"] as? String {
                        /// When signing up, the user image is store as "empty"
                        if userImage != ApplicationConstants.dbEmptyValue {
                            /// Get a reference to the image using the URL
                            let ref = Storage.storage().reference(forURL: userImage)
                            
                            /// Get the image data
                            ref.getData(maxSize: 1000000, completion: { (data, error) in
                                if error != nil {
                                    print(ApplicationConstants.profilePictureDownloadErrorMessage)
                                } else {
                                    if let imageData = data {
                                        if let image = UIImage(data: imageData) {
                                            /// Store the image data inside the image view
                                            self.notificationSenderProfilePicImageView.image = image
                                            
                                            /// Animate the image view will a duration of 0.5 seconds
                                            UIView.animate(withDuration: 0.5, animations: { () -> Void in
                                                self.notificationSenderProfilePicImageView.alpha = 1
                                            })
                                            
                                            self.notificationSenderActivityIndicatorView.stopAnimating()
                                            self.notificationSenderActivityIndicatorView.isHidden = true
                                        }
                                    }
                                }
                            })
                        } else {
                            /// If the image URL is "empty", load the default empty pic
                            let image = #imageLiteral(resourceName: "empy_profile_pic")
                            self.notificationSenderProfilePicImageView.image = image
                            UIView.animate(withDuration: 0.5, animations: { () -> Void in
                                self.notificationSenderProfilePicImageView.alpha = 1
                            })
                            
                            self.notificationSenderActivityIndicatorView.stopAnimating()
                            self.notificationSenderActivityIndicatorView.isHidden = true
                        }
                    }
                }
            }
        }
    }
}
