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
import AVFoundation

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
    var members:[Member]?
    var currentCall:Call?
    
    
    @IBAction func doneAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        Nexmo.shared.getUsers { (error, json) in
            DispatchQueue.main.async {
                self.allUsers = json
                self.loadUsers()
            }
        }
        
        conversation?.members.asObservable.subscribe { state in
            DispatchQueue.main.async {
                self.loadUsers()
                switch state {
                case .invited(let member): print("\(member) invited"); break
                case .joined(let member):  print("\(member) joined"); break
                case .left(let member):  print("\(member) left"); break
                }
            }
        }
        
        if (conversation?.media.state.value == Media.State.connected) {
            self.joinCallButton.setTitle("Disconnect Audio Call", for: .normal)
        }
        
    }
    
    
    func loadUsers() {
        guard let allUsers = self.allUsers else {
            return
        }
        
        self.availableUsers.removeAll()
        //filter all users from users already in conversation
        for (_,user):(String, JSON) in allUsers {
            let member = self.conversation?.members.filter({ (member) -> Bool in
                return member.user.name == user["name"].stringValue
            }).first
            
            if (member == nil) {
                self.availableUsers.append(user)
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
        requestAudioPermission { (success) in
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
            self.conversation?.requireSync = true
        }) { (error) in
            print("kick error", error)
        }
        
    }
    
    //MARK: UserCellDelegate
    func addUser(_ cell: UserCell) {
        guard let user = cell.user else {
            return
        }
        
        //TODO: using memberId returned error
        conversation?.join(username: user["name"].stringValue, memberId:nil, onSuccess: {
            print("user added")
            self.conversation?.requireSync = true
        }, onError: { (error) in
            print("user add error", error)
        })
    }
    
    private func connectAudio() {
        requestAudioPermission { (success) in
            if (success) {
                do {
                    try self.conversation?.media.enable().subscribe(onSuccess: { (state) in
                        DispatchQueue.main.async {
                            print("connectAudio State \(state.rawValue)")
                            if (state == Media.State.connecting) {
                                self.toast(title: "Connecting")
                            } else if (state == Media.State.connected) {
                                self.joinCallButton.setTitle("Disconnect Audio Call", for: .normal)
                                self.toast(title: "Connected")
                            } else if (state == Media.State.disconnected || state == Media.State.failed) {
                                self.joinCallButton.setTitle("Join Audio Call", for: .normal)
                                self.toast(title: "Disconnected")
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
    
    private func requestAudioPermission(completion: @escaping (_ success:Bool) -> Void) {
        
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

extension ConversationInfoViewController: UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return (conversation?.members.count)!
        } else {
            return availableUsers.count
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        if (indexPath.section == 0) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "memberCell", for: indexPath) as! MemberCell
            cell.delegate = self
            let member = conversation?.members[indexPath.row]
            cell.member = member
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as! UserCell
            cell.delegate = self
            let user = availableUsers[indexPath.row]
            cell.user = user
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
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
            
            if ( member?.user.isMe)! {
                userName.font = UIFont.boldSystemFont(ofSize: 15)
                
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

