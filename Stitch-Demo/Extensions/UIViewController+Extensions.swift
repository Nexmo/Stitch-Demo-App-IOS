//
//  UIAlertController+Extensions.swift
//  Stitch-Demo
//
//  Created by Tony Hung on 6/19/18.
//  Copyright © 2018 Nexmo. All rights reserved.
//

import Foundation
import UIKit
extension UIViewController {
    func presentAlert(title:String, message:String? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true)
        
    }
}
