//
//  ConversationInfoViewController.swift
//  Stitch-Demo
//
//  Created by Tony Hung on 6/14/18.
//  Copyright © 2018 Tony Hung. All rights reserved.
//

import UIKit
import Stitch
import SwiftyJSON

class ConversationInfoViewController: UIViewController, MemberCellDelegate, UserCellDelegate {
   
    

    @IBOutlet weak var tableView: UITableView!
    var conversation: Conversation?
    var availableUsers = [JSON]()
    var members:[Member]?
    
    
    @IBAction func doneAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        conversation?.members.memberChangesObjc(onInvited: { (_) in
            self.loadUsers()
        }, onJoined: { (_) in
            self.loadUsers()
        }, onLeft: { (_) in
            self.loadUsers()
        })
        self.loadUsers()
    }
    
    func loadUsers() {
        Nexmo.shared.getUsers { (error, json) in
            DispatchQueue.main.async {
                self.availableUsers.removeAll()
                //filter all users from users already in conversation
                for (_,user):(String, JSON) in json {
                    let member = self.conversation?.members.filter({ (member) -> Bool in
                        return member.user.name == user["name"].stringValue
                    }).first
                    
                    if (member == nil) {
                        self.availableUsers.append(user)
                    }
                }
                self.tableView.reloadData()
            }
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func joinAudioAction(_ sender: Any) {
    }
    @IBAction func leaveConvAction(_ sender: Any) {
    }
    
    //MARK: MemberCellDelegate
    func callUser(_ cell: MemberCell) {
        guard let member = cell.member else {
            return
        }
    }
    
    func kickUser(_ cell: MemberCell) {
        guard let member = cell.member else {
            return
        }
        //TODO: kicked user does not get removed from list
        member.kick({
            print("kicked")
            self.loadUsers()
            self.tableView.reloadData()
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

            //TODO: reload
            self.loadUsers()
        }, onError: { (error) in
            print("user add error", error)
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

