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

class InitalViewController: BaseViewController {

    let introText = "Welcome to Awesome Chat. Click the Get Started button!"

    @IBOutlet weak var logoutButton: UIBarButtonItem! {
        didSet {
            logoutButton.isEnabled = false
        }
    }
    
    @IBOutlet weak var infoLabel: UILabel! {
        didSet {
            infoLabel.text = introText
            infoLabel.isEnabled = false

        }
    }
    @IBOutlet weak var chatButton: UIButton! {
        didSet {
            chatButton.isEnabled = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        client.account.state.subscribe(onSuccess: { (account_state) in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                switch account_state {
                case .loggedIn(let session):
                    self.logoutButton.isEnabled = true
                    self.chatButton.isEnabled =  true
                    self.infoLabel.text = "User " + (session.name) + " Logged in"
                case .loggedOut:
                    self.infoLabel.text = self.introText
                    self.logoutButton.isEnabled = true
                    self.chatButton.isEnabled =  false
                }
            }
            
        }) { (_) in }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        client.account.state.unsubscribe()
    }

    @IBAction func logoutAction(_ sender: Any) {
        client.logout()
        infoLabel.text = introText
        
        let alert = UIAlertController(title: "Logout Successful", message: nil, preferredStyle:.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
        infoLabel.text = "Logout Successful"
    }
    
    @IBAction func getStartedAction(_ sender: Any) {
        let alert = UIAlertController(title: "Are you a new or returning user", message: nil, preferredStyle:.actionSheet)
        alert.addAction(UIAlertAction(title: "New User", style: .default) { [weak self] _ in
            self?.presentNewUser()
        })
        
        alert.addAction(UIAlertAction(title: "Returning User", style: .default) { [weak self] _ in
            self?.getUsers()
        })
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func chatAction(_ sender: Any) {
        performSegue(withIdentifier: "listConversations", sender: nil)
    }
    
    
    func presentNewUser() {
        let alert = UIAlertController(title: "Whats your username", message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Create User", style: .default) { [weak self] _ in
            let textField = alert.textFields![0] as UITextField
            self?.showHUD()
            Nexmo.shared.createUser(textField.text!, completion: { (success) in
                DispatchQueue.main.async {
                    if (success) {
                        Nexmo.shared.authenticateUser(textField.text!) { [weak self] (error, json) in
                            self?.hideHUD()
                            let token = json["user_jwt"].stringValue
                            print(token)
                            self?.doLogin(token)
                        }
                    }
                }
            })
        })
        alert.addAction(UIAlertAction(title: "Create User as Admin", style: .default) { [weak self] _ in
            let textField = alert.textFields![0] as UITextField
            self?.showHUD()
            Nexmo.shared.createUser(textField.text!, admin: true) { (success) in
                DispatchQueue.main.async {
                    if (success) {
                        Nexmo.shared.authenticateUser(textField.text!) { [weak self] (error, json) in
                            self?.hideHUD()
                            let token = json["user_jwt"].stringValue
                            print("user \(textField.text!) token: \(token)")
                            self?.doLogin(token)
                        }
                    }
                }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addTextField { (textField) in
            textField.placeholder = "Username"
        }
        present(alert, animated: true) {
            
        }
    }
    
    func getUsers() {
        let alert = UIAlertController(title: "Select User", message: nil, preferredStyle:.actionSheet)

        showHUD()
        Nexmo.shared.getUsers { [weak self] (error, json) in
            self?.hideHUD()
            for (_, user) in json {
                print(user)
                alert.addAction(UIAlertAction(title: user["name"].stringValue, style: .default) { [weak self] _ in
                    print("selected", user["href"])
                    self?.showHUD()
                    Nexmo.shared.authenticateUser(user["name"].stringValue) { [weak self] (error, json) in
                        let token = json["user_jwt"].stringValue
                        print(token)
                        self?.doLogin(token)
                    }
                })
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self?.present(alert, animated: true)
        }
    }
    
    func doLogin(_ token:String) {
        
        print("DEMO - login called on client.")
        client.login(with: token).subscribe(onSuccess: {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.hideHUD()
                self.presentAlert(title: "Login Successful")
                print("DEMO - login susbscribing with token.")
                print("self.client.account", self.client.account)
            }
            
        }, onError: { error in
            
            print(error.localizedDescription)

            
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

