//
//  User.swift
//  Commonality
//
//  Created by Thabo David Klass on 27/05/2018.
//  Copyright © 2018 Spreebie, Inc. All rights reserved.
//

import Foundation

/// The User class
class User {
    /// A private holder for the key
    private var _key: String? = nil
    
    /// A private holder for the creation timestamp
    private var _creationAt: Int? = nil
    
    /// A private holder for the device arn
    private var _deviceArn: String? = nil
    
    /// A private holder for the device token
    private var _deviceToken: String? = nil
    
    /// A private holder for the email
    private var _email: String? = nil
    
    /// A private holder for the first name
    private var _firstName: String? = nil
    
    /// A private holder for the last name
    private var _lastName: String? = nil
    
    /// A private holder for the full name
    private var _fullName: String? = nil
    
    /// A private holder for the measuring system
    private var _measuringSystem: String? = nil
    
    /// A private holder for the profile picture file name
    private var _profilePictureFileName: String? = nil
    
    /// A private holder for the update timestamp
    private var _updatedAt: Int? = nil
    
    // A private holder for interests
    private var _interests: [String]? = nil
    
    // A private holder for institution
    private var _institution: String? = nil
    
    // A private holder for role details
    private var _roleDetails: String? = nil
    
    /// The key getter
    var key: String? {
        return _key
    }
    
    /// The created at getter
    var creationAt: Int? {
        return _creationAt
    }
    
    /// The device ARN getter
    var deviceArn: String? {
        return _deviceArn
    }
    
    /// The device token getter
    var deviceToken: String? {
        return _deviceToken
    }
    
    /// The email getter
    var email: String? {
        return _email
    }
    
    /// The first name getter
    var firstName: String? {
        return _firstName
    }
    
    /// The last name getter
    var lastName: String? {
        return _lastName
    }
    
    /// The full name getter
    var fullName: String? {
        return _fullName
    }
    
    /// The measuring system getter
    var measuringSystem: String? {
        return _measuringSystem
    }
    
    /// The profile picture file name getter
    var profilePictureFileName: String? {
        return _profilePictureFileName
    }
    
    /// The updatedAt getter
    var updatedAt: Int? {
        return _updatedAt
    }
    
    /// The updatedAt getter
    var interests: [String]? {
        return _interests
    }
    
    /// The institution getter
    var institution: String? {
        return _institution
    }
    
    /// The role details getter
    var roleDetails: String? {
        return _roleDetails
    }
    
    /// A constuctor that takes the key and a dictionary that contains
    /// user data
    init(key: String, userData: Dictionary<String, AnyObject>) {
        _key = key
        
        if let creationAt = userData["creationAt"] as? Int {
            _creationAt = creationAt
        }
        
        if let deviceArn = userData["deviceArn"] as? String {
            _deviceArn = deviceArn
        }
        
        if let deviceToken = userData["deviceToken"] as? String {
            _deviceToken = deviceToken
        }
        
        if let email = userData["email"] as? String {
            _email = email
        }
        
        if let firstName = userData["firstName"] as? String {
            _firstName = firstName
        }
        
        if let lastName = userData["lastName"] as? String {
            _lastName = lastName
        }
        
        if let fullName = userData["fullName"] as? String {
            _fullName = fullName
        }
        
        if let measuringSystem = userData["measuringSystem"] as? String {
            _measuringSystem = measuringSystem
        }
        
        if let profilePictureFileName = userData["profilePictureFileName"] as? String {
            _profilePictureFileName = profilePictureFileName
        }
        
        if let updatedAt = userData["updatedAt"] as? Int {
            _updatedAt = updatedAt
        }
        
        if let interests = userData["interests"] as? [String] {
            _interests = interests
        }
        
        if let institutuon = userData["school"] as? String {
            _institution = institutuon
        }
        
        if let roleDetails = userData["roleDetails"] as? String {
            _roleDetails = roleDetails
        }
    }
}

