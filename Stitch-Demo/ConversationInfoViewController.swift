//
//  ConversationInfoViewController.swift
//  Stitch-Demo
//
//  Created by Tony Hung on 6/14/18.
//  Copyright © 2018 Nexmo. All rights reserved.
//

import UIKit
import Stitch
import SwiftyJSON

class ConversationInfoViewController: UIViewController, MemberCellDelegate, UserCellDelegate {
   
    
    /// Nexmo Conversation client
    let client: ConversationClient = {
        return ConversationClient.instance
    }()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var joinCallButton: UIButton!
    var conversation: Conversation?
    var availableUsers = [JSON]()
    var allUsers:JSON?
    var currentCall:Call?
    
    var members:[Member]?
    
    @IBAction func doneAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.navigationItem.title = conversation?.name
        
        //TODO: load users only once
        Nexmo.shared.getUsers { (error, json) in
            DispatchQueue.main.async {
                self.allUsers = json
                self.loadUsers()
            }
        }
        self.loadUsers()
        
        if (conversation?.media.state.value == Media.State.connected) {
            self.joinCallButton.setTitle("Disconnect Audio Call", for: .normal)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        conversation?.members.asObservable.subscribe({ (member_state) in
            print("member_state",member_state)
            self.loadUsers()
        })
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        conversation?.members.asObservable.unsubscribe()
    }
    
    
    func loadUsers() {
        
        members = self.conversation?.members.filter({ (member) -> Bool in
            return member.state == .joined
        })
        
        if self.allUsers != nil {
            self.availableUsers.removeAll()
            
            //filter all users from users already jonied in conversation
            for (_,user):(String, JSON) in allUsers! {
                let member = members?.filter({ (member) -> Bool in
                    return member.user.name == user["name"].stringValue
                }).first
                
                if (member == nil) {
                    self.availableUsers.append(user)
                }
            }
        }
    
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func joinAudioAction(_ sender: Any) {
        
        if (conversation?.media.state.value != Media.State.connected) {
            connectAudio()
        } else {
            disconnectAudio()
        }
    }
    
    @IBAction func leaveConvAction(_ sender: Any) {
        
        //TODO: error when leaving conversation CSI-780
        conversation?.leave({
            //return to conversation list VC
            let viewControllers = self.navigationController!.viewControllers as [UIViewController];
            for aViewController:UIViewController in viewControllers {
                if aViewController.isKind(of: ConversationsTableViewController.self) {
                    _ = self.navigationController?.popToViewController(aViewController, animated: true)
                }
            }
            
        }, onError: { (error) in
            print("user left error", error)
        })
    }
    

    //MARK: MemberCellDelegate
    func callUser(_ cell: MemberCell) {
        guard let member = cell.member else {
            return
        }
        let storyboard = UIStoryboard(name: UIStoryboard.Storyboard.main.filename, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CallViewController") as! CallViewController
        vc.caller = member.user.name
        
        let nav = UINavigationController(rootViewController: vc)
        self.present(nav, animated: true, completion: nil)
        return

        

        
        
        if (currentCall != nil) {
            print("cant call user, already connected")
            currentCall?.hangUp(onSuccess: {
                print("Call hangUp from dismiss of view controller")
                cell.callButton.setTitle("Call", for: .normal)
            }, onError: { error in
                print("Call hangup failed", error)
            })
            
//            currentCall?.memberState.unsubscribe()
//            currentCall?.state.unsubscribe()
            currentCall = nil
            return
        }
        AudioController.shared.requestAudioPermission { (success) in
            if (success) {
                self.client.media.call([member.user.name], onSuccess: { result in
                    // if you would like to display a UI for calling...
                    self.currentCall = result.call
                    cell.callButton.setTitle("In Progress", for: .normal)
                    result.call.loudspeaker = true
                }, onError: { networkError in
                    print("error",networkError)
                    // if you would like to display a log for error...
                })
                
            }
        }
    

    }
    
    func kickUser(_ cell: MemberCell) {
        guard let member = cell.member else {
            return
        }
        
        //TODO: kicked user does not get removed from list CSI-781
        member.kick({
            print("kicked")
            self.presentAlert(title: member.user.name + " removed")
        }) { (error) in
            print("kick error", error)
        }
        
    }
    
    //MARK: UserCellDelegate
    func addUser(_ cell: UserCell) {
        guard let user = cell.user else {
            return
        }
        
        self.conversation?.join(username: user["name"].stringValue).subscribe(onSuccess: { (_) in
            self.presentAlert(title: "User Added")

        }, onError: { (error) in
            self.presentAlert(title: "Error Adding User", message: error.localizedDescription)
        })
    }
    
    private func connectAudio() {
        AudioController.shared.requestAudioPermission { (success) in
            if (success) {
                do {
                    try self.conversation?.media.enable().subscribe(onSuccess: { (state) in
                        DispatchQueue.main.async {
                            print("connectAudio State \(state.rawValue)")
                            if (state == Media.State.connecting) {
                            } else if (state == Media.State.connected) {
                                self.joinCallButton.setTitle("Disconnect Audio Call", for: .normal)
                            } else if (state == Media.State.disconnected || state == Media.State.failed) {
                                self.joinCallButton.setTitle("Join Audio Call", for: .normal)
                            } else {
                                
                            }
                        }

                    }, onError: { (error) in
                        print("enableAudio error", error)
                        self.joinCallButton.titleLabel?.text = error.localizedDescription
                    })
                } catch let error {
                    print("enableAudio error", error)
                    self.disconnectAudio()
                }
            }
        }
    }
    
    private func disconnectAudio() {
        
        //TODO: CSI-783
        self.conversation?.media.disable()
        print("audio disconnected")
        self.joinCallButton.setTitle("Join Audio Call", for: .normal)
    }
    
    private func invite(userId: String?, username: String, withAudio audio: Bool) {
        conversation?.invite(username, userId: userId, with: audio ? .audio(muted: false, earmuffed: false) : nil)
            .subscribe(onError: { [weak self] _ in
                self?.presentAlert(title: "Error", message: "Failed to invite user")
            })
    }

}

extension ConversationInfoViewController: UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return members?.count ?? 0
        } else {
            return availableUsers.count
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        if (indexPath.section == 0) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "memberCell", for: indexPath) as! MemberCell
            cell.delegate = self
            cell.member = members?[indexPath.row]
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as! UserCell
            cell.delegate = self
            let user = availableUsers[indexPath.row]
            cell.user = user
            return cell
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0) {
            return "Users"
        } else {
            return "All Members"
        }
    }
}

protocol MemberCellDelegate {
    func callUser(_ cell: MemberCell)
    func kickUser(_ cell: MemberCell)
}

class MemberCell:UITableViewCell {
    
    var delegate:MemberCellDelegate?
    
    var member:Member? {
        didSet {
            userName.text = member?.user.name
            userID.text = member?.user.uuid
            callButton.isEnabled = true

            if ( member?.user.isMe)! {
                userName.font = UIFont.boldSystemFont(ofSize: 15)
                callButton.isEnabled = false
            }
        }
    }
    
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userID: UILabel!
    @IBOutlet weak var callButton: UIButton!
    
    @IBAction func callAction(_ sender: Any) {
        delegate?.callUser(self)
    }
    
    @IBAction func kickAction(_ sender: Any) {
        delegate?.kickUser(self)
    }
}

protocol UserCellDelegate {
    func addUser(_ cell: UserCell)
}

class UserCell:UITableViewCell {
    
    var delegate:UserCellDelegate?
    
    var user:JSON? {
        didSet {
            userName.text = user!["name"].stringValue
        }
    }
    
    @IBOutlet weak var userName: UILabel!
    
    @IBAction func addUserAction(_ sender: Any) {
        delegate?.addUser(self)
    }
    
}

