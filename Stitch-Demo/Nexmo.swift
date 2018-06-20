//
//  Nexmo.swift
//  Stitch-Demo
//
//  Created by Tony Hung on 6/13/18.
//  Copyright © 2018 Nexmo. All rights reserved.
//

import UIKit
import SwiftyJSON
class Nexmo: NSObject {
    let baseURL = "https://aqueous-sea-78840.herokuapp.com/api"
    
    static let shared = Nexmo()
    
    func getUsers(completion: @escaping (Error?, JSON) -> Void) {
        let urlString = baseURL + "/users"
        
        let task = URLSession.shared.dataTask(with: URL(string: urlString)!) { (data, response, error) in
            if error != nil {
                completion(error, JSON.null)
            } else {
                if let usableData = data {
                    
                    do {
                        let json = try JSON(data: usableData)
                        completion(nil, json)
                    } catch let error {
                        print(error.localizedDescription)
                        completion(error, JSON.null)
                    }
                }
            }
        }
        task.resume()
    }
    
    func authenticateUser(_ user:String, completion: @escaping (Error?, JSON) -> Void) {
        let urlString = baseURL + "/jwt/"+user

        let task = URLSession.shared.dataTask(with: URL(string: urlString)!) { (data, response, error) in
            if error != nil {
                completion(error, JSON.null)
            } else {
                if let usableData = data {
                    let json = try! JSON(data: usableData)
                    
                    completion(nil, json)
                }
            }
        }
        task.resume()
    }
}
