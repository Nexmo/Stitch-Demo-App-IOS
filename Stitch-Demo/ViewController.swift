//
//  ViewController.swift
//  Stitch-Demo
//
//  Created by Tony Hung on 6/11/18.
//  Copyright © 2018 Nexmo. All rights reserved.
//

import UIKit
import Stitch
import SwiftyJSON

class ViewController: UIViewController {

    @IBOutlet weak var logoutButton: UIBarButtonItem!
    
    /// Nexmo Conversation client
    let client: ConversationClient = {
        return ConversationClient.instance
    }()
    @IBOutlet weak var infoLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        infoLabel.text = "Welcome to Awesome Chat. Click the Get Started button!"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateLogoutState()
        

        super.viewDidAppear(animated)
    }

    @IBAction func logoutAction(_ sender: Any) {
        client.logout()
        updateLogoutState()
        
        let alert = UIAlertController(title: "Logout Successful", message: nil, preferredStyle:.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
        infoLabel.text = "Logout Successful"
    }
    
    @IBAction func getStartedAction(_ sender: Any) {
        let alert = UIAlertController(title: "Are you a new or returning user", message: nil, preferredStyle:.actionSheet)
        alert.addAction(UIAlertAction(title: "New User", style: .default, handler: { (action) in
            self.presentNewUser()
        }))
        
        alert.addAction(UIAlertAction(title: "Returning User", style: .default, handler: { (action) in
            self.getUsers()
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func chatAction(_ sender: Any) {
        guard self.client.account.user != nil else {
            let alert = UIAlertController(title: "LOGIN", message: "The `.user` property on self.client.account is nil", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return print("DEMO - chat self.client.account.user is nil");
        }
        performSegue(withIdentifier: "listConversations", sender: nil)
    }
    
    
    func presentNewUser() {
        let alert = UIAlertController(title: "Whats your username", message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Create User", style: .default, handler: { (action) in
            
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addTextField { (textField) in
            textField.placeholder = "Username"
        }
        present(alert, animated: true) {
            
        }
    }
    
    func getUsers() {
        let alert = UIAlertController(title: "Select User", message: nil, preferredStyle:.actionSheet)

        Nexmo.shared.getUsers { (error, json) in
            for (_,user):(String, JSON) in json {
                print(user)
                alert.addAction(UIAlertAction(title: user["name"].stringValue, style: .default, handler: { (action) in
                    print("selected", user["href"])
                    
                    Nexmo.shared.authenticateUser(user["name"].stringValue, completion: { (error, json) in
                        let token = json["user_jwt"].stringValue
                        print(token)
                        self.doLogin(token)
                    })
                }))
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        }
    }
    func updateLogoutState() {
        self.logoutButton.isEnabled = (client.account.user != nil)
        if (client.account.user != nil) {
            self.infoLabel.text = "User " + (client.account.user?.name)! + " Logged in"
        }

    }
    
    func doLogin(_ token:String) {
        
        print("DEMO - login called on client.")
        
        client.login(with: token).subscribe(onSuccess: {
            DispatchQueue.main.async {

                print("DEMO - login susbscribing with token.")
                print("self.client.account", self.client.account)
                //TODO: self.client.account.user is nill
                if let user = self.client.account.user {

                    print("DEMO - login successful and here is our \(user)")
                } // insert activity indicator to track subscription
                self.updateLogoutState()
            }
            
        }, onError: { [weak self] error in
            
            print(error.localizedDescription)
            self?.updateLogoutState()

            
            // remove to a function
            let reason: String = {
                switch error {
                case LoginResult.failed: return "failed"
                case LoginResult.invalidToken: return "invalid token"
                case LoginResult.sessionInvalid: return "session invalid"
                case LoginResult.expiredToken: return "expired token"
                case LoginResult.success: return "success"
                default: return "unknown"
                }
            }()
            
            print("DEMO - login unsuccessful with \(reason)")
        })
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

