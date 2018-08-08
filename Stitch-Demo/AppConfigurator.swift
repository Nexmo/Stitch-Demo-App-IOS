//
//  AppConfigurator.swift
//  ConversationDemo
//
//  Created by shams ahmed on 19/09/2016.
//  Copyright © 2016 Nexmo. All rights reserved.
//

import Foundation
import UIKit
import Stitch
import AVFoundation
import UserNotifications

/// App Configurator
internal class AppConfigurator: NSObject, UNUserNotificationCenterDelegate {
    
    /// App launch options
    private let launchOptions: [UIApplicationLaunchOptionsKey: Any]?
    
    internal let push = PushConfigurator()
    
    // MARK:
    // MARK: Initializers
    
    internal init(launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        self.launchOptions = launchOptions
        
        super.init()
        
        setup()
    }
    
    // MARK:
    // MARK: Setup
    
    private func setup() {
        setupAudio()
        setupNotifications()
    }
    
    internal func setupNetworkActivity() {
        guard ConversationClient.hasToken else { return }
        
        ConversationClient.instance.state.subscribe { state in
            print("DEMO - Client state: .\(state)")
            
            UIApplication.shared
                .isNetworkActivityIndicatorVisible = state != .synchronized
        }
    }
    
    private func setupNotifications() {
        let center = UNUserNotificationCenter.current()
        
        center.delegate = self
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()
    }
    
    private func setupAudio() {
        do {
            let session = AVAudioSession.sharedInstance()
            
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try? session.setMode(AVAudioSessionModeVoiceChat)
            
            session.requestRecordPermission { _ in }
        } catch let error {
            print("Demo - " + error.localizedDescription)
        }
    }
    
    // MARK:
    // MARK: UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("userNotificationCenter will present", notification)
        
        // must call completionHandler() for the system badge to be displayed
        completionHandler([.alert, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("DEMO - didReceive notification response")
        
        // Pass to SDK
        ConversationClient.instance.appLifecycle.push.userNotificationCenter(
            didReceive: response,
            withCompletionHandler: completionHandler
        )
        
        completionHandler()
    }
    
    // MARK:
    // MARK: Helper
    
    private func shouldShowNotification() -> Bool {
       return true
    }
}
