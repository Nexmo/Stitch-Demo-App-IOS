//
//  UITableView+Extension.swift
//  Stitch-Demo
//
//  Created by Tony Hung on 6/14/18.
//  Copyright © 2018 Nexmo. All rights reserved.
//

import Foundation
import UIKit


extension UITableView {
    
    func setEmptyMessage(_ message: String) {

        let messageLabel = UILabel(frame: CGRect(origin: .zero, size: bounds.size))
        messageLabel.text = message
        messageLabel.textColor = .black
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.sizeToFit()
        
        backgroundView = messageLabel
        separatorStyle = .none
    }
    
    func restore() {
        backgroundView = nil
        separatorStyle = .singleLine
    }
}
