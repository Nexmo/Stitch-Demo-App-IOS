//
//  BaseViewController.swift
//  Stitch-Demo
//
//  Created by Tony Hung on 7/31/18.
//  Copyright © 2018 Tony Hung. All rights reserved.
//

import UIKit
import Stitch

//TODO: think about how to do this better.
//Should be one base vc for all viewcontrollers

class BaseViewController: UIViewController {

    let client: ConversationClient = {
        let config = Stitch.Configuration.init(with: .info,
                                               autoReconnect: false,
                                               autoDownload: false,
                                               clearAllData: true,
                                               pushNotifications: true)
        ConversationClient.configuration = config
        return ConversationClient.instance
    }()

}

class BaseTableViewController: UITableViewController {
    
    let client: ConversationClient = {
        let config = Stitch.Configuration.init(with: .info,
                                               autoReconnect: false,
                                               autoDownload: false,
                                               clearAllData: true,
                                               pushNotifications: true)
        ConversationClient.configuration = config
        return ConversationClient.instance
    }()
    
}
