//
//  ProgressHUD+extensions.swift
//  Stitch-Demo
//
//  Created by Tony Hung on 7/9/18.
//  Copyright © 2018 Tony Hung. All rights reserved.
//

import UIKit

import Foundation
import MBProgressHUD
import QuartzCore

extension UITableViewController {
    func showHudForTable(_ message: String) {
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.label.text = message
        hud.isUserInteractionEnabled = false
        hud.layer.zPosition = 2
        self.tableView.layer.zPosition = 1
    }
}

extension UIViewController {
    func showHUD(_ message: String? = "") {
        DispatchQueue.main.async {

            let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            hud.label.text = message
            hud.isUserInteractionEnabled = false
        }
    }
    
    func hideHUD() {
        DispatchQueue.main.async() {
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }
}

