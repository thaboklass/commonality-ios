//
//  ApplicationConstants.swift
//  Spreebie
//
//  Created by Thabo David Klass on 03/06/2017.
//  Copyright © 2017 Spreebie, Inc. All rights reserved.
//

import Foundation

struct ApplicationConstants {
    /// The Commonality AWS identity pool ID
    static var commonalityIdentityPoolID: String = "us-east-1:f400df9a-28f6-49e7-8ce1-2c88ee5f0840"
    
    /// The Commonality S3 bucket
    static var commonalityS3Bucket: String = "commonality-userfiles-mobilehub-271607515"
    
    /// The Commonality SNS platform application ARN
    static var commonalitySNSPlatformApplicationArn: String = "arn:aws:sns:us-east-1:203525439813:app/APNS_SANDBOX/CommonalitySNSDevelopment"
    //static var commonalitySNSPlatformApplicationArn: String = "arn:aws:sns:us-east-1:203525439813:app/APNS/CommonalitySNSProduction"
    
    /// The Commonality APNS type
    //static var commonalityAPNSType: String = "APNS_SANDBOX"
    static var commonalityAPNSType: String = "APNS"
    
    // The Commonality In-App Purchases ID
    static var commonalityInAppPurchasesID: String = "Commonality9GigsFor30Days"
    
    /// The URL to the Commonality terms
    static var commonalityTermsURL: String = "http://openbeacon.biz/?p=758"
    
    /// The URL to the Commonality contact us
    static var commonalityContactUSURL: String = "http://getspreebie.com/#contact"
    
    /// The URL to the Commonality privacy policy
    static var commonalityPrivacyPolicyURL: String = "http://openbeacon.biz/?p=754"
    
    /// The URL to the Commonality landing page
    static var commonalityLandingPageURL: String = "http://openbeacon.biz/?p=764"
    
    /// The database empty value string
    static var dbEmptyValue: String = "empty"
    
    /// The profile picture download error message
    static var profilePictureDownloadErrorMessage: String = "Could not load image."
    
    /// The Commonality user ID key value
    static var commonalityUserIDKey: String = "commonalityUID"
    
    /// The login button text
    static var commonalityLoginButtonValue: String = "Login"
    
    /// Commonality user just logged out value
    static var commonalityUserJustLoggedOutValue: String = "commonalityJustLoggedOut"
    
    /// Commonality application's small "no" value
    static var commonalitySmallNoValue: String = "no"
    
    /// Commonality application's small "yes" value
    static var commonalitySmallYesValue: String = "yes"
    
    /// Commonality user just logged in value
    static var commonalityUserJustLoggedInValue: String = "commonalityJustLoggedIn"
    
    /// Has the view controller segued
    static var hasASeguedHappenedInTheHomePage: Bool = false
}
