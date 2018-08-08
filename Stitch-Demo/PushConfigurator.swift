//
//  PushConfigurator.swift
//  ConversationDemo
//
//  Created by Shams Ahmed on 17/04/18.
//  Copyright © 2018 Nexmo. All rights reserved.
//

import UserNotifications
import Stitch

struct PushConfigurator {
    
    // MARK:
    // MARK: Initializers
    
    internal init() {
        
    }
    
    // MARK:
    // MARK: Setup
    
    internal func bind() {
        print("DEMO: Binding push notification")
        
      
        
        // listen for push notifications
        ConversationClient.instance.appLifecycle.push.notifications
            .subscribe { notification in
                print("DEMO: Notification received: \(notification)")
                
                let title: String
                let body: String
                let path: String?
                
                switch notification {
                case .conversation(let conversation, let reason):
                    switch reason {
                    case .new: title = "MemberInvite notification"
                    case .invitedBy: title = "Member Invite via invitedBy notification"
                    }
                    
                    body = conversation.name
                    path = nil
                case .text(let event):
                    title = "Text notification"
                    body = event.text ?? "Blank text"
                    path = nil
                case .image(let event):
                    let thumbnail = event.path(of: .thumbnail)
                    
                    title = "Image notification"
                    body = thumbnail == nil ? "Downloading image... " : "Image"
                    path = thumbnail
                }
                
                LocalNotification(title: title, body: body, imagePath: path).fire { error in
                    if let error = error {
                        print("DEMO - Failed to show notification: \(error)")
                        
                        return
                    }
                    
                    print("DEMO - Will show notification: \(title)")
                }
                
        }
    }
}
