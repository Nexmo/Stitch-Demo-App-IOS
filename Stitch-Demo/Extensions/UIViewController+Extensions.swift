//
//  UIAlertController+Extensions.swift
//  Stitch-Demo
//
//  Created by Tony Hung on 6/19/18.
//  Copyright © 2018 Tony Hung. All rights reserved.
//

import Foundation
import UIKit
extension UIViewController {
    func toast(title:String, message:String? = nil, duration:Double = 0.5) {
        let toast = UIAlertController(title: title, message: message, preferredStyle: .alert)
        self.present(toast, animated: true)
        let time: DispatchTime = .now() + duration

        DispatchQueue.main.asyncAfter(deadline:time) {
            self.dismiss(animated: true, completion: nil)
        }
    }
}
