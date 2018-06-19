//
//  ChatTableViewController.swift
//  Stitch-Demo
//
//  Created by Tony Hung on 6/13/18.
//  Copyright © 2018 Tony Hung. All rights reserved.
//

import UIKit
import Stitch

class ChatTableViewController: UIViewController, UITextFieldDelegate {

    var conversation: Conversation?
    /// Nexmo Conversation client
    let client: ConversationClient = {
        return ConversationClient.instance
    }()
    var constraints:[NSLayoutConstraint] = []
    
    @IBOutlet weak var tableView: UITableView!
    var containerViewBottomAnchor: NSLayoutConstraint?
    
    lazy var inputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter message..."
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        return textField
    }()

    
    lazy var inputContainerView: UIView = {
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
//        containerView.backgroundColor = UIColor.green
    
        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: UIControlState())
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        containerView.addSubview(sendButton)
        
        //x,y,w,h
        constraints.append(sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor))
        constraints.append(sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor))
        constraints.append(sendButton.widthAnchor.constraint(equalToConstant: 80))
        constraints.append(sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor))
        
        containerView.addSubview(self.inputTextField)
        //x,y,w,h
      

        constraints.append(self.inputTextField.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8))
        constraints.append(self.inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor))
        constraints.append(self.inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor))
        constraints.append(self.inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor))
        
        return containerView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create the info button
        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(getInfo(_:)), for: .touchUpInside)
        let infoBarButtonItem = UIBarButtonItem(customView: infoButton)
        self.navigationItem.rightBarButtonItem = infoBarButtonItem
        
        
        //TODO: listen to call events
        
        inputTextField.becomeFirstResponder()
        tableView.keyboardDismissMode = .interactive
        
        
        setupInputComponents()
        setupKeyboardObservers()
        activateConstraints()
        
        
    
        // listen for messages
        conversation!.events.newEventReceived.subscribe(onSuccess: { event in
            print("event \(event)")
            // refresh tableView
            self.tableView.reloadData()
        })
        
        conversation!.events.forEach({ event in
            print(event)
        })
    }
    
    @objc func getInfo(_ sender:UIBarButtonItem) {
        performSegue(withIdentifier: "getInfo", sender: nil)

    }

    func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
    
    @objc func handleSend() {
        do {
            // send method
            try conversation?.send(self.inputTextField.text!)
            
        } catch let error {
            print(error)
        }
        tableView.reloadData()
        self.inputTextField.text = nil
        self.view.endEditing(true)

    }
    @objc func handleKeyboardWillShow(_ notification: Notification) {
        let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        
        containerViewBottomAnchor?.constant = -keyboardFrame!.height
        tableView.contentInset.bottom = keyboardFrame!.height
        tableView.scrollIndicatorInsets.bottom = keyboardFrame!.height

        UIView.animate(withDuration: keyboardDuration!, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    
    @objc func handleKeyboardWillHide(_ notification: Notification) {
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        
        containerViewBottomAnchor?.constant = 0
        tableView.contentInset.bottom = 0
        tableView.scrollIndicatorInsets.bottom = 0

        UIView.animate(withDuration: keyboardDuration!, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    func setupInputComponents() {
        let containerView = UIView()
//        containerView.backgroundColor = UIColor.purple
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(containerView)
        
        //ios9 constraint anchors
        //x,y,w,h
        
        constraints.append(containerView.leftAnchor.constraint(equalTo: view.leftAnchor))
        
        containerViewBottomAnchor = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        constraints.append(containerViewBottomAnchor!)
//        containerViewBottomAnchor?.isActive = true
        
        constraints.append(containerView.widthAnchor.constraint(equalTo: view.widthAnchor))
        constraints.append(containerView.heightAnchor.constraint(equalToConstant: 50))
        containerView.addSubview(inputContainerView)
    }
    func deactivateConstraints() {
        for constraint in constraints {
            constraint.isActive = false
        }
    }
    func activateConstraints() {
        
        for constraint in constraints {
            constraint.isActive = true
        }
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        print("willAnimateRotation", toInterfaceOrientation)
//        self.view.setNeedsUpdateConstraints()
        self.view.removeConstraints(constraints)
        deactivateConstraints()
        self.view.addConstraints(constraints)
        activateConstraints()
    }
    
   
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "getInfo" {
            let destinationNavigationController = segue.destination as! ConversationInfoViewController
//            let targetController = destinationNavigationController.topViewController as! ConversationInfoViewController
            destinationNavigationController.conversation = conversation
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension ChatTableViewController: UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversation!.events.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = UIColor.white
        cell.accessoryType = UITableViewCellAccessoryType.none

        let event = conversation?.events[indexPath.row]
        switch event {
        case is TextEvent:
            let textEvent = (event as! TextEvent)
            //Is this how we get the seen receipt?
            let receipt = textEvent.receiptForMember(textEvent.fromMember!)
            if (receipt != nil) {
                if (receipt?.state == ReceiptRecord.State.seen) {
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                }
            }
            
            cell.textLabel?.text = textEvent.text
            cell.detailTextLabel?.text = (textEvent.from?.name)! + " " + (event?.createDate.description)!
            break
        case is MediaEvent:
            let mediaEvent = (event as! MediaEvent)
            
            cell.textLabel?.text =  (mediaEvent.from?.name)! + " " + (mediaEvent.enabled ? "enabled audio" : "disabled audio")
            cell.detailTextLabel?.text = mediaEvent.createDate.description
            break
        case is MemberJoinedEvent:
            let memberJoinedEvent = (event as! MemberJoinedEvent)
            cell.textLabel?.text =  (memberJoinedEvent.from?.name)! + " joined"
            cell.detailTextLabel?.text = memberJoinedEvent.createDate.description
            break
        case is MemberInvitedEvent:
            let memberInvited = (event as! MemberInvitedEvent)
            cell.textLabel?.text =  (memberInvited.from?.name)! + " invited"
            cell.detailTextLabel?.text = memberInvited.createDate.description
            break
        case is MemberLeftEvent:
            let memberLeft = (event as! MemberLeftEvent)
            cell.textLabel?.text =  (memberLeft.from?.name)! + " left"
            cell.detailTextLabel?.text = memberLeft.createDate.description
            break
        
        default:
            cell.textLabel?.text = ""
        }

        return cell;
    }
}
