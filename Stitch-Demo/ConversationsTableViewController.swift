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

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createConversation(_:)))
        self.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        client.conversation.conversations.asObservable.subscribe { (result) in
            self.reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        client.conversation.conversations.asObservable.unsubscribe()
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
        
        /* A row has been swiped, so show the appropriate options. */
        guard let conv = sortedConversations?[indexPath.row]  else { return nil }
        
        /* Leave option. */
        let leave = UITableViewRowAction(style: .normal, title: "Leave", handler: { (_, indexPath: IndexPath!) -> Void in
            /* Issue leave. */
            _ = conv.leave().subscribe(onSuccess: { [weak self] in
                self?.reloadData()
            })
        })
        
        leave.backgroundColor = UIColor.red
        
        return [leave]
    }
    
    public override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        /* Dont allow editing (i.e. show leave button) if already left the conversation */
        guard let conv = sortedConversations?[indexPath.row]  else { return false }
        return !(conv.state == .left)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "viewConversation", sender: indexPath)
        
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
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

