//
//  PhotoViewController.swift
//  Stitch-Demo
//
//  Created by Tony Hung on 6/20/18.
//  Copyright © 2018 Tony Hung. All rights reserved.
//

import UIKit

class PhotoViewController: UIViewController {

   
    var image:UIImage?
    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()

         imageView.image = image
    }
    
    @IBAction func closeAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
