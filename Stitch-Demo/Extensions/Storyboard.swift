//
//  Storyboard.swift
//  Stitch-Demo
//
//  Created by Tony Hung on 6/21/18.
//  Copyright © 2018 Tony Hung. All rights reserved.
//

import UIKit

//https://medium.com/swift-programming/uistoryboard-safer-with-enums-protocol-extensions-and-generics-7aad3883b44d
extension UIStoryboard {
    
    enum Storyboard: String {
        case main
        var filename: String {
            return rawValue.capitalized
        }
    }
    
    convenience init(storyboard: Storyboard, bundle: Bundle? = nil) {
        self.init(name: storyboard.filename, bundle: bundle)
    }
}
