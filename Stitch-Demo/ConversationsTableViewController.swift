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
        
        client.conversation.conversations.conversationsChangesObjc(onInserted: { (_) in
            print("conversations inserted")
            self.reloadData()
        }, onInsertedWithInvitedBy: { (_, _, _) in
            print("conversations inserted with invite")
            self.reloadData()
        }, onUpdated: { (_) in
            print("conversations updated")
            self.reloadData()
        }) { (_) in
            print("conversations deleted")
            self.reloadData()
        }
        self.reloadData()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createConversation(_:)))
    }
    
    func reloadData() {
        sortedConversations = client.conversation.conversations.sorted(by: { $0.creationDate.compare($1.creationDate) == .orderedDescending })
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationItem.title = "Conversations"
        super.viewWillAppear(animated)
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
    
    //TODO: update `delete` text to `leave`
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let conv = sortedConversations![indexPath.row] as Conversation
            conv.leave({
                tableView.deleteRows(at: [indexPath], with: .fade)
            }) { (error) in
                print(error)
            }
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "viewConversation", sender: indexPath)
        
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "viewConversation" {
            let row = (sender as! IndexPath).row;
            let conv = client.conversation.conversations[row] as Conversation
            let chatVC = segue.destination as? ChatTableViewController
            chatVC?.conversation = conv
        }
    }
    

}

