//
//  CommonalityNotification.swift
//  Commonality
//
//  Created by Thabo David Klass on 15/06/2018.
//  Copyright © 2018 Spreebie, Inc. All rights reserved.
//

import Foundation

/// The Commonality Notification class
class CommonalityNotification {
    /// A private holder for the key
    private var _key: String? = nil
    
    /// A private holder for the creation timestamp
    private var _creationAt: Int? = nil
    
    /// A private holder for the actor
    private var _actor: String? = nil
    
    /// A private holder for the actor name
    private var _actorName: String? = nil
    
    /// A private holder for the notification type
    private var _notificationType: String? = nil
    
    /// A private holder for the update timestamp
    private var _updatedAt: Int? = nil
    
    /// The key getter
    var key: String? {
        return _key
    }
    
    /// The created at getter
    var creationAt: Int? {
        return _creationAt
    }
    
    /// The actor getter
    var actor: String? {
        return _actor
    }
    
    /// The actor name getter
    var actorName: String? {
        return _actorName
    }
    
    /// The notification type getter
    var notificationType: String? {
        return _notificationType
    }
    
    /// The updatedAt getter
    var updatedAt: Int? {
        return _updatedAt
    }
    
    /// A constuctor that takes the key and a dictionary that contains
    /// user data
    init(key: String, userData: Dictionary<String, AnyObject>) {
        _key = key
        
        if let creationAt = userData["creationAt"] as? Int {
            _creationAt = creationAt
        }
        
        if let actor = userData["actor"] as? String {
            _actor = actor
        }
        
        if let actorName = userData["actorName"] as? String {
            _actorName = actorName
        }
        
        if let notificationType = userData["notificationType"] as? String {
            _notificationType = notificationType
        }
        
        if let updatedAt = userData["updatedAt"] as? Int {
            _updatedAt = updatedAt
        }
    }
}

