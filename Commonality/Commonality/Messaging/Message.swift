//
//  Message.swift
//  MessagingApp
//
//  Created by Thabo David Klass on 03/07/2017.
//  Copyright © 2017 Spreebie, Inc. All rights reserved.
//

import Foundation
import FirebaseDatabase

/// The messages class for the Firebase-based chat
class Message {
    /// A private holder for the message
    private var _message: String!
    
    /// A private holder for the sender
    private var _sender: String!
    
    /// A private holder for the seen boolean
    private var _seen: Bool!
    
    /// A private holder for the time stamp
    private var _timeStamp: Int!
    
    /// A private holder for the message key
    private var _messageKey: String!
    
    /// A priavte holder for the message reference
    private var _messageRef: DatabaseReference!
    
    /// The current user's Firebase UID
    var currentUser = KeychainWrapper.standard.string(forKey: "commonalityID")
    
    /// The message getter
    var message: String {
        return _message
    }
    
    /// The sender getter
    var sender: String {
        return _sender
    }
    
    /// The seen boolean getter
    var seen: Bool {
        return _seen
    }
    
    /// The time stamp getter
    var timeStamp: Int {
        return _timeStamp
    }
    
    /// The message key getter
    var messageKey: String {
        return _messageKey
    }
    
    /// A constructor that takes the message, the sender and the seen boolean
    init(message: String, sender: String, seen: Bool, timeStamp: Int) {
        _message = message
        
        _sender = sender
        
        _seen = seen
        
        _timeStamp = timeStamp
    }
    
    /// A constructor that takes the message key and a dictionary that contains
    /// the message, the sender and the seen boolean
    init(messageKey: String, postData: Dictionary<String, AnyObject>) {
        _messageKey = messageKey
        
        if let message = postData["message"] as? String {
            _message = message
        }
        
        if let sender = postData["sender"] as? String {
            _sender = sender
        }
        
        if let seen = postData["seen"] as? Bool {
            _seen = seen
        }
        
        if let timeStamp = postData["time_stamp"] as? Int {
            _timeStamp = timeStamp
        }
        
        _messageRef = Database.database().reference().child("messages").child(_messageKey)
    }
}
