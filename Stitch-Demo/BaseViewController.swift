//
//  BaseViewController.swift
//  Stitch-Demo
//
//  Created by Tony Hung on 7/31/18.
//  Copyright © 2018 Tony Hung. All rights reserved.
//

import UIKit
import StitchClient
//TODO: think about how to do this better.
//Should be one base vc for all viewcontrollers

class BaseViewController: UIViewController {

    let client: NXMStitchClient = {
        
        return NXMStitchClient.init()
    }()

}

class BaseTableViewController: UITableViewController {
    
    let client: NXMStitchClient = {
       
        return NXMStitchClient.init()   
    }()
    
}
