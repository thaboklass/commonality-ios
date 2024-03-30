//
//  MessageDetailCell.swift
//  MessagingApp
//
//  Created by Thabo David Klass on 03/07/2017.
//  Copyright © 2017 Spreebie, Inc. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseDatabase
import FirebaseFirestore

/// The message detail cell class for the Firebase-based chat
class MessageDetailCell: UITableViewCell {
    /// The message recipeint's image view
    @IBOutlet weak var recipientImg: UIImageView!
    
    //@IBOutlet weak var borderView: UIView!
    
    /// The message recipient's image name label
    @IBOutlet weak var recipientName: UILabel!
    
    /// The message recipient's chat preview label
    @IBOutlet weak var chatPreview: UILabel!
    
    @IBOutlet weak var recipientImageActivityIndicatorView: UIActivityIndicatorView!
    
    
    /// The message detail associated with this cell
    var messageDetail: MessageDetail!
    
    /// The current user's Firebase UID
    var currentUser = KeychainWrapper.standard.string(forKey: ApplicationConstants.commonalityUserIDKey)

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        /// Start the image view out as invisible
        recipientImg.alpha = 0
        
        /// Create rounded corners
        let purplish = UIColor(red: 192.0/255.0, green: 30.0/255.0, blue: 201.0/255.0, alpha: 1.0)
        
        let cellImageLayer: CALayer? = recipientImg.layer
        cellImageLayer!.borderWidth = 2.0
        cellImageLayer!.borderColor = purplish.cgColor
        
        cellImageLayer!.cornerRadius = recipientImg.frame.height / 2 // 6
        //cellImageLayer!.cornerRadius = 8
        cellImageLayer!.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    /**
     Sets the cell data from Firebase.
     
     - Parameters:
     - none
     
     - Returns: void.
     */
    func cofigureCell(messageDetail: MessageDetail) {
        recipientImageActivityIndicatorView.startAnimating()
        
        /// set the message detail
        self.messageDetail = messageDetail
        
        /// Set the chat preview to the latest message
        chatPreview.text = self.messageDetail.lastMessage
        
        // Get firestore dBase
        let dBase = Firestore.firestore()
        
        let userRef = dBase.collection("users").document(messageDetail.recipient)
        
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let userDict = document.data() {
                    /// Check for nil again
                    if let username = userDict["fullName"] as? String, let userImage = userDict["profilePictureFileName"] as? String {
                        /// Set the username into the recipient label
                        self.recipientName.text = username
                        
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
                                            self.recipientImg.image = image
                                            
                                            /// Animate the image view will a duration of 0.5 seconds
                                            UIView.animate(withDuration: 0.5, animations: { () -> Void in
                                                self.recipientImg.alpha = 1
                                            })
                                            
                                            self.recipientImageActivityIndicatorView.stopAnimating()
                                            self.recipientImageActivityIndicatorView.isHidden = true
                                        }
                                    }
                                }
                            })
                        } else {
                            /// If the image URL is "empty", load the default empty pic
                            let image = #imageLiteral(resourceName: "empy_profile_pic")
                            self.recipientImg.image = image
                            UIView.animate(withDuration: 0.5, animations: { () -> Void in
                                self.recipientImg.alpha = 1
                            })
                            
                            self.recipientImageActivityIndicatorView.stopAnimating()
                            self.recipientImageActivityIndicatorView.isHidden = true
                        }
                    }
                }
            }
        }
    }
}
