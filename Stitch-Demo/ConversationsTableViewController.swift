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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sortedConversations = client.conversation.conversations.sorted(by: { $0.creationDate.compare($1.creationDate) == .orderedDescending })
        tableView.reloadData()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createConversation(_:)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let user = self.client.account.user {
            self.navigationItem.title = user.name
        }
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func createConversation(_ sender:UIBarButtonItem) {
        let alert = UIAlertController(title: "New Conversation", message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { (action) in
            let textField = alert.textFields![0] as UITextField
            _ = self.client.conversation.new(textField.text!, withJoin: true).subscribe(onError: { error in
                print(error)
                print("DEMO - chat creation unsuccessful with \(error.localizedDescription)")
            })
        }))
        alert.addTextField { (textField) in
            textField.placeholder = "Enter name for conversation"
        }
        present(alert, animated: true)
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sortedConversations!.count == 0 {
            self.tableView.setEmptyMessage("No Conversations")
        } else {
            self.tableView.restore()
        }
        
        return sortedConversations!.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let conv = sortedConversations![indexPath.row] as Conversation
        cell.textLabel?.text = conv.name
        cell.detailTextLabel?.text = conv.uuid

        return cell
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "viewConversation", sender: indexPath)
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "viewConversation" {
            let row = (sender as! IndexPath).row; //we know that sender is an NSIndexPath here.
            let conv = client.conversation.conversations[row] as Conversation
            let chatVC = segue.destination as? ChatTableViewController
            chatVC?.conversation = conv

        }
    }
    

}

extension UITableView {
    
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .black
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = .center;
        messageLabel.sizeToFit()
        
        self.backgroundView = messageLabel;
        self.separatorStyle = .none;
    }
    
    func restore() {
        self.backgroundView = nil
        self.separatorStyle = .singleLine
    }
}
