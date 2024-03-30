//
//  AppDelegate.swift
//  Commonality
//
//  Created by Thabo David Klass on 07/05/2018.
//  Copyright © 2018 Spreebie, Inc. All rights reserved.
//

import UIKit
import CoreData
import FirebaseCore
import FBNotifications
import FBSDKCoreKit
import UserNotifications
import AWSSNS
import FirebaseFirestore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?

    /// The SNS Platform application ARN
    let SNSPlatformApplicationArn = ApplicationConstants.commonalitySNSPlatformApplicationArn
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Connect to Firebase
        FirebaseApp.configure()
        
        // Connect to Facebook
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // Load AWS credentials
        let credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: AWSRegionType.USEast1, identityPoolId: ApplicationConstants.commonalityIdentityPoolID)
        
        // Setup AWS service configuration
        let defaultServiceConfiguration = AWSServiceConfiguration(
            region: AWSRegionType.USEast1, credentialsProvider: credentialsProvider)
        
        // Assign the default service configuration
        AWSServiceManager.default().defaultServiceConfiguration = defaultServiceConfiguration
        
        // Customize the appearance of the Navigation Bar and the Tab Bar
        let purplish = UIColor(red: 192.0/255.0, green: 30.0/255.0, blue: 201.0/255.0, alpha: 1.0)
        
        UINavigationBar.appearance().tintColor = purplish
        
        UITabBar.appearance().barTintColor = UIColor.white
        UITabBar.appearance().tintColor = purplish
        
        // Register for push notifications
        registerForPushNotifications(application: application)
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if #available(iOS 9.0, *) {
            let handled = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String, annotation: options[UIApplicationOpenURLOptionsKey.annotation])
            
            return handled
        } else {
            // Fallback on earlier versions
        }
        
        if #available(iOS 9.0, *) {
            let handled = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String, annotation: options[UIApplicationOpenURLOptionsKey.annotation])
            
            return handled
        } else {
            // Fallback on earlier versions
        }
        
        return false
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        /// Set the device token for analytics
        FBSDKAppEvents.setPushNotificationsDeviceToken(deviceToken)
        
        /// Attach the device token to the user defaults
        var token = ""
        for i in 0..<deviceToken.count {
            token = token + String(format: "%02.2hhx", arguments: [deviceToken[i]])
        }
        print(token)
        UserDefaults.standard.set(token, forKey: "deviceTokenForSNS")
        /// Create a platform endpoint. In this case, the endpoint is a
        /// device endpoint ARN
        let sns = AWSSNS.default()
        let request = AWSSNSCreatePlatformEndpointInput()
        request?.token = token
        request?.platformApplicationArn = SNSPlatformApplicationArn
        sns.createPlatformEndpoint(request!).continueWith(executor: AWSExecutor.mainThread(), block: { (task: AWSTask!) -> AnyObject! in
            if task.error != nil {
                print("Error: \(String(describing: task.error))")
            } else {
                let createEndpointResponse = task.result! as AWSSNSCreateEndpointResponse
                if let endpointArnForSNS = createEndpointResponse.endpointArn {
                    print("endpointArn: \(endpointArnForSNS)")
                    UserDefaults.standard.set(endpointArnForSNS, forKey: "endpointArnForSNS")
                }
            }
            return nil
        })
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        /// Log push events on FB Analytics
        FBSDKAppEvents.logPushNotificationOpen(userInfo)
    }
    
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable : Any], completionHandler: @escaping () -> Void) {
        /// Log a push notification open on FB Analytics
        FBSDKAppEvents.logPushNotificationOpen(userInfo, action: identifier)
    }
    
    /// Present In-App Notification from remote notification (if present).
    private func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        FBNotificationsManager.shared().presentPushCard(forRemoteNotificationPayload: userInfo, from: nil) { viewController, error in
            if error != nil {
                completionHandler(.failed)
            } else {
                completionHandler(.newData)
            }
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        /// Activate FB Analytics for Spreebie
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        //self.saveContext()
    }
    
    func registerForPushNotifications(application: UIApplication) {
        /// The notifications settings
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert], completionHandler: {(granted, error) in
                if (granted)
                {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                else{
                    //Do stuff if unsuccessful…
                }
            })
        } else {
            let settings = UIUserNotificationSettings(types: [UIUserNotificationType.alert, UIUserNotificationType.badge, UIUserNotificationType.sound], categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
    }
    
    // Called when a notification is delivered to a foreground app.
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("User Info (willPresent) = ",notification.request.content.userInfo)
        
        print(notification.request.content.body)
        
        
        let notificationBody = notification.request.content.body
        
        if notificationBody == "You have received a new direct message." {
            if let myTabBarController = self.window?.rootViewController as? UITabBarController {
                if let tabBarItems = myTabBarController.tabBar.items {
                    if let messagesItem = tabBarItems[2] as? UITabBarItem {
                        messagesItem.badgeValue = "1"
                    }
                }
            }
        } else {
            if let myTabBarController = self.window?.rootViewController as? UITabBarController {
                if let tabBarItems = myTabBarController.tabBar.items {
                    if let messagesItem = tabBarItems[1] as? UITabBarItem {
                        messagesItem.badgeValue = "1"
                    }
                }
            }
        }
        
        completionHandler([.alert, .badge, .sound])
    }
    // Called to let your app know which action was selected by the user for a given notification.
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("User Info (didReceive) = ",response.notification.request.content.userInfo)
        
        let notificationBody = response.notification.request.content.body
        
        if notificationBody == "You have received a new direct message." {
            if let myTabBarController = self.window?.rootViewController as? UITabBarController {
                if let tabBarItems = myTabBarController.tabBar.items {
                    if let messagesItem = tabBarItems[2] as? UITabBarItem {
                        messagesItem.badgeValue = "1"
                    }
                }
            }
        } else {
            if let myTabBarController = self.window?.rootViewController as? UITabBarController {
                if let tabBarItems = myTabBarController.tabBar.items {
                    if let messagesItem = tabBarItems[1] as? UITabBarItem {
                        messagesItem.badgeValue = "1"
                    }
                }
            }
        }
        
        completionHandler()
    }
}

