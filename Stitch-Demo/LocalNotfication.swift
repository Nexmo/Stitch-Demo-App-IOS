//
//  LocalNotification.swift
//  Stitch
//
//  Created by Shams Ahmed on 14/03/18.
//  Copyright © 2018 Nexmo. All rights reserved.
//

import UserNotifications
import MobileCoreServices

// Display local notification
internal struct LocalNotification {
    
    // alert title
    internal let title: String
    
    // alert body
    internal let body: String
    
    // image path
    internal let imagePath: String?
    
    // build request
    private var request: UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = "App"
        content.sound = UNNotificationSound.default()
        
        // add image via image path
        if let imagePath = imagePath {
            let url = URL(fileURLWithPath: imagePath)
            
            do {
                content.attachments = [try UNNotificationAttachment(
                    identifier: imagePath,
                    url: url,
                    options: [UNNotificationAttachmentOptionsTypeHintKey: kUTTypeJPEG]) ]
            } catch {
                print("Demo - Failed to display image: \(error.localizedDescription) from path: \(imagePath)")
            }
        }
        
        // create a request to fire
        return UNNotificationRequest(
            identifier: "App",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.0001, repeats: false)
        )
    }
    
    // MARK:
    // MARK: Initializers
    
    internal init(title: String, body: String, imagePath: String?=nil) {
        self.title = title
        self.body = body
        self.imagePath = imagePath
    }
    
    // MARK:
    // MARK: Display
    
    /// show local alert
    internal func fire(_ completionHandler: ((Error?) -> Void)?=nil) {
        UNUserNotificationCenter.current().add(request, withCompletionHandler: completionHandler)
    }
}
