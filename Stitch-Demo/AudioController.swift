//
//  AudioController.swift
//  Stitch-Demo
//
//  Created by Tony Hung on 6/21/18.
//  Copyright © 2018 Tony Hung. All rights reserved.
//

import UIKit
import AVFoundation

class AudioController: NSObject {

    static let shared = AudioController()
    
    func requestAudioPermission(completion: @escaping (_ success:Bool) -> Void) {
        
        do {
            let session = AVAudioSession.sharedInstance()
            
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
            session.requestRecordPermission { (success) in
                completion(success)
            }
        } catch  {
            print(error)
            completion(false)
            
        }
    }
}
