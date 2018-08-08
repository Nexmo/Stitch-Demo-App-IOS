//
//  AppDelegate.swift
//  ConversationDemo
//
//  Created by James Green on 22/08/2016.
//  Copyright © 2016 Nexmo. All rights reserved.
//

import UIKit
import Stitch

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    
    /// Conversation client
    lazy var client: ConversationClient = {
        // Optional: Set custom configuration like logs, endpoint and other feature flags
        ConversationClient.configuration = Configuration(with: .info)
        
        return ConversationClient.instance
    }()
    
    // MARK:
    // MARK: Application
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        
        ConversationClient.instance.appLifecycle.push.notifications
            .subscribe { notification in
                print("Notification received: \(notification)")
        }

        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        
        
        return true
    }
    
    // MARK:
    // MARK: Notification
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("DEMO - did register for remote notification")
        
        // Pass to SDK
        client.appLifecycle.push.registeredForRemoteNotifications(with: deviceToken)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("DEMO - did receive remote notification")
        
        // Pass to SDK
        client.appLifecycle.push.receivedRemoteNotification(userInfo, fetchCompletionHandler: completionHandler)
    }
}
