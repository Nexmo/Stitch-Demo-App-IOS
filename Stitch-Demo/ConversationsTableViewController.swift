 //
//  StitchConversationsTableViewController.swift
//  IceBreaker
//
//  Created by Tony Hung on 5/31/18.
//  Copyright © 2018 Vonage. All rights reserved.
//

import UIKit
import Stitch


class ConversationsTableViewController: UITableViewController {

    var sortedConversations:[Conversation]?
    /// Nexmo Conversation client
    let client: ConversationClient = {
        return ConversationClient.instance
    }()
    var selectedConversation:Conversation?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Conversations"

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createConversation(_:)))
        let callButton = UIBarButtonItem(title: "Call", style: .plain, target: self, action: #selector(makePhoneCall(_:)))
        self.navigationItem.rightBarButtonItems = [addButton, callButton]
        
        client.conversation.conversations.asObservable.subscribe { [weak self] change in
            self?.reloadData()
        }
        
        client.media.inboundCalls.subscribe { [weak self] call in
            print("New inbound call from: \(call.from?.user.displayName ?? "unknown")")
            
            
            let names = call.to.map { $0.user.name }
            let title = "Call from: \(call.from?.user.name ?? "Unknown")"
            let message = names.joined(separator: ", ")
            
            
            let calling = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert
            )
            
            calling.addAction(UIAlertAction(title: "Answer", style: .default, handler: { [weak self] _ in
                print("DEMO - Will answer call")
                
                call.answer(onSuccess: {
                    AudioController.shared.requestAudioPermission { (success) in
                        if success {
                            let storyboard = UIStoryboard(name: UIStoryboard.Storyboard.main.filename, bundle: nil)
                            let vc = storyboard.instantiateViewController(withIdentifier: "CallViewController") as! CallViewController
                            vc.call = call
                            
                            let nav = UINavigationController(rootViewController: vc)
                            self?.present(nav, animated: true, completion: nil)
                        }
                    }
                }, onError: { [weak self] error in
                    self?.presentAlert(title: "Failed to answer call", message: error.localizedDescription)
                })
            }))
            
            calling.addAction(UIAlertAction(title: "Reject", style: .destructive, handler: { _ in
                call.reject()
            }))
            
            self?.present(calling, animated: true)
    }
        
        self.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func reloadData() {
        sortedConversations = client.conversation.conversations.sorted(by: { $0.creationDate.compare($1.creationDate) == .orderedDescending })
        tableView.reloadData()
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func createConversation(_ sender:UIBarButtonItem) {
        let alert = UIAlertController(title: "New Conversation", message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { (action) in
            let textField = alert.textFields![0] as UITextField
            self.newConversation(textField.text!)
        }))
        alert.addTextField { (textField) in
            textField.placeholder = "Enter name for conversation"
        }
        present(alert, animated: true)
        
    }
    
    @objc func makePhoneCall(_ sender:UIBarButtonItem) {
        let alert = UIAlertController(title: "New Call", message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { (action) in
            let phoneNumber = "18457297292"//alert.textFields![0] as UITextField
            
            AudioController.shared.requestAudioPermission { (success) in
                if success {
                    self.client.media.callPhone(phoneNumber, onSuccess: { [weak self] result in
                        let storyboard = UIStoryboard(name: UIStoryboard.Storyboard.main.filename, bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "CallViewController") as! CallViewController
                        vc.call = result.call
                        
                        let nav = UINavigationController(rootViewController: vc)
                        self?.present(nav, animated: true, completion: nil)
                        }, onError: { error in
                            print("Call user error", error)
                    })
                }
            }            
        }))
        alert.addTextField { (textField) in
            textField.placeholder = "Phone Number"
        }
        present(alert, animated: true)
    }

    func newConversation(_ text:String) {
        self.client.conversation.new(with: text, shouldJoin: true, { (conversation) in
            print("success")
            DispatchQueue.main.async {
                self.presentAlert(title: "Conversation Created")
                self.sortedConversations = self.client.conversation.conversations.sorted(by: { $0.creationDate.compare($1.creationDate) == .orderedDescending })
                self.tableView.reloadData()
            }
        }, onError: { (error) in
            print("error", error)
        }, onComplete: {
            print("done")
        })
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let _ = sortedConversations else {
            self.tableView.setEmptyMessage("No Conversations")
            return 0
        }
        
        self.tableView.restore()
        return sortedConversations!.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let conv = sortedConversations![indexPath.row] as Conversation
        cell.textLabel?.text = conv.name
        cell.detailTextLabel?.text = conv.uuid

        return cell
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        guard let conv = sortedConversations?[indexPath.row]  else { return nil }
        
        let leave = UITableViewRowAction(style: .normal, title: "Leave", handler: { (_, indexPath: IndexPath!) -> Void in
            _ = conv.leave().subscribe(onSuccess: { [weak self] in
                self?.reloadData()
            })
        })
        
        leave.backgroundColor = UIColor.red
        
        return [leave]
    }
    
    public override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let conv = sortedConversations?[indexPath.row]  else { return false }
        return !(conv.state == .left)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "viewConversation", sender: indexPath)
    }

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "viewConversation" {
            guard let row = (sender as? IndexPath)?.row, let conv = sortedConversations?[row] else {
                return
            }
            
            let chatVC = segue.destination as? ChatTableViewController
            chatVC?.conversation = conv
        }
    }
    

}

