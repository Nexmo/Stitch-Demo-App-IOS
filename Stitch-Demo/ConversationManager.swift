//
//  ConversationManager.swift
//  Stitch-Demo
//
//  Created by Tony Hung on 11/20/18.
//  Copyright © 2018 Tony Hung. All rights reserved.
//

import Foundation
import StitchClient
class ConversationManager {
    
    static let shared = ConversationManager()
    
    let client: NXMStitchCore = {
        return NXMStitchCore.init()!
    }()
    
    var currentUser:NXMUser?

}
