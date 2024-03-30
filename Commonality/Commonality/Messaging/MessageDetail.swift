//
//  MessageDetail.swift
//  MessagingApp
//
//  Created by Thabo David Klass on 03/07/2017.
//  Copyright © 2017 Spreebie, Inc. All rights reserved.
//

import Foundation
import FirebaseDatabase

/// The messages detail class for the Firebase-based chat
class MessageDetail {
    /// A private holder for the recipient
    private var _recipient: String!
    
    /// A private holder for the last message
    private var _lastMessage: String!
    
    /// A private holder for whether or not the message has been seen
    private var _seen: Bool!
    
    /// A priavte holder for the time stamp
    private var _timeStamp: Int!
    
    /// A private holder for the message key -> ID
    private var _messageKey: String!
    
    /// The current user's Firebase UID
    var currentUser = KeychainWrapper.standard.string(forKey: ApplicationConstants.commonalityUserIDKey)
    
    /// The recipient getter
    var recipient: String {
        return _recipient
    }
    
    /// The last message getter
    var lastMessage: String {
        return _lastMessage
    }
    
    /// The seen boolean getter
    var seen: Bool {
        return _seen
    }
    
    /// The time stamp getter
    var timeStamp: Int {
        return _timeStamp
    }
    
    /// The message key (ID) getter
    var messageKey: String {
        return _messageKey
    }
    
    /// A constructor that takes a recipient
    init(recipient: String) {
        _recipient = recipient
    }
    
    
    /// A constructor that takes the last message
    init(lastMessage: String) {
        _lastMessage = lastMessage
    }
    
    /// A constructor that takes the seen boolean
    init(seen: Bool) {
        _seen = seen
    }
    
    /// A constructor that take the time stamp
    init(timeStamp: Int) {
        _timeStamp = timeStamp
    }
    
    /// A constuctor that takes the message key and a dictionary that contains
    /// a recipient, last message and a seen boolean
    init(messageKey: String, messageData: Dictionary<String, AnyObject>) {
        _messageKey = messageKey
        
        if let recipient = messageData["recipient"] as? String {
            _recipient = recipient
        }
        
        if let lastMessage = messageData["lastmessage"] as? String {
            _lastMessage = lastMessage
        }
        
        if let seen = messageData["seen"] as? Bool {
            _seen = seen
        }
        
        if let timeStamp = messageData["time_stamp"] as? Int {
            _timeStamp = timeStamp
        }
    }
}
