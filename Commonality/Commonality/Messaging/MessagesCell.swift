//
//  MessagesCell.swift
//  MessagingApp
//
//  Created by Thabo David Klass on 03/07/2017.
//  Copyright © 2017 Spreebie, Inc. All rights reserved.
//

import UIKit

/// The messages cell calss for the Firebase-based chat
class MessagesCell: UITableViewCell {
    /// The received messages label
    @IBOutlet weak var receivedMessageLabel: UILabel!
    
    /// The received messages view - the message container
    @IBOutlet weak var receivedMessageView: UIView!
    
    /// The sent messages label
    @IBOutlet weak var sentMessageLabel: UILabel!
    
    /// The sent messages view - the message container
    @IBOutlet weak var sentMessageView:UIView!
    
    /// The actual message - contains sender and message data
    var message: Message!
    
    /// The current user's Firebase UID
    var currentUser = KeychainWrapper.standard.string(forKey: ApplicationConstants.commonalityUserIDKey)

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        /// Created rounded corners for the received messages
        let receivedMessageViewLayer: CALayer?  = receivedMessageView.layer
        receivedMessageViewLayer!.cornerRadius = 8
        
        /// Create a shadow
        receivedMessageViewLayer!.shadowColor = UIColor.black.cgColor
        receivedMessageViewLayer!.shadowOffset = CGSize(width: 0, height: 1.20)
        receivedMessageViewLayer!.shadowRadius = 1.20
        receivedMessageViewLayer!.shadowOpacity = 0.6
        
        /// Created rounded corners for the sent messages
        let sentMessageViewLayer: CALayer?  = sentMessageView.layer
        sentMessageViewLayer!.cornerRadius = 8
        
        /// Create a shadow
        sentMessageViewLayer!.shadowColor = UIColor.black.cgColor
        sentMessageViewLayer!.shadowOffset = CGSize(width: 0, height: 1.20)
        sentMessageViewLayer!.shadowRadius = 1.20
        sentMessageViewLayer!.shadowOpacity = 0.6
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
    func configCell(message: Message) {
        /// Set the message
        self.message = message
        
        if currentUser != nil {
            print("The sender is: \(message.sender)")
            
            /// The message was sent by the current user, put it on the right
            if message.sender == currentUser! {
                sentMessageView.isHidden = true
                
                sentMessageLabel.text = ""
                
                receivedMessageView.isHidden = false
                
                receivedMessageLabel.text = message.message
                
            /// The message was sent by the someone else, put it on the left
            } else {
                sentMessageView.isHidden = false
                
                sentMessageLabel.text = message.message
                
                receivedMessageView.isHidden = true
                
                receivedMessageLabel.text = ""
            }
        }
    }
}
