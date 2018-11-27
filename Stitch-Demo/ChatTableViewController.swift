//
//  ChatTableViewController.swift
//  Stitch-Demo
//
//  Created by Tony Hung on 6/13/18.
//  Copyright © 2018 Nexmo. All rights reserved.
//

import UIKit
import StitchClient
import SDWebImage
class ChatTableViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, NXMConversationEventsControllerDelegate {

    var conversation: NXMConversationDetails?
    var eventsController:NXMConversationEventsController?
    var conversationEvents:[NXMEvent] = []
    var conversationMessageStatuses: [Int:NXMMessageStatusType] = [:]
    var memberLookup: [String: NXMMember] = [:]
    let imagePicker = UIImagePickerController()
    
    @IBOutlet weak var containerView: UIView!
    
    // a set of unique members typing
    private var whoIsTyping = Set<String>()
    
    @IBOutlet weak var bottomLayoutContraint: NSLayoutConstraint?
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var isTypingLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = conversation?.displayName

        // Create the info button
        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(getInfo(_:)), for: .touchUpInside)
        let infoBarButtonItem = UIBarButtonItem(customView: infoButton)
        navigationItem.rightBarButtonItem = infoBarButtonItem
        
        inputTextField.becomeFirstResponder()
        tableView.keyboardDismissMode = .interactive
        ConversationManager.shared.client.getConversationDetails((conversation?.uuid)!, onSuccess: { (conversationDetails) in
//            print(conversationDetails)
            for member in conversationDetails!.members {
                print(member)
                self.memberLookup[member.memberId] = member
            }
        }) { (error) in
            print(error)
        }
        
        ConversationManager.shared.client.getEventsInConversation((conversation?.uuid)!, onSuccess: { (events) in
            DispatchQueue.main.async {
                guard let _ = events as? [NXMEvent] else {
                    return
                }
                for event in events! {
                    let nxmEvent = (event as! NXMEvent)
                    if nxmEvent.type != NXMEventType.messageStatus {
                        self.conversationEvents.append(nxmEvent)
                    } else {
                        let statusEvent = event as! NXMMessageStatusEvent
                        self.conversationMessageStatuses[statusEvent.eventId] = statusEvent.status
                    }
                }
                self.tableView.reloadData()
            }
        }) { (error) in
            print(error)
        }
        
      
//        setupKeyboardObservers()
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        // listen for messages
//        conversation!.events.newEventReceived.subscribe(onSuccess: { [weak self] event in
//            print("newEventReceived \(event)")
//            self?.tableView.reloadData()
//        })
//        
//        // listen for typing
//        conversation?.members.forEach { member in
//            member.typing
//                .subscribe(onSuccess: { [weak self] (typing) in
//                    print("isTyping",typing)
//                    self?.handleTypingChangedEvent(member: member, isTyping: typing)
//                }, onError: { (error) in
//                    print("error")
//                })
//        }
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    @objc func getInfo(_ sender:UIBarButtonItem) {
        performSegue(withIdentifier: "getInfo", sender: nil)

    }
    @IBAction func sendPhoto(_ sender: Any) {
        
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func sendText(_ sender: Any) {
    }
    
    func setupKeyboardObservers() {
       
    }
    
    //MARK: TextField Delegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    //Mark UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage, let data = UIImageJPEGRepresentation(image, 1.0) else {
            return
        }
        
        // send method
        //TODO
//        conversation?.sendAttachment(of: .image, withName: "My Image", data: data, completion: { [weak self] (error) in
//            guard let _ = error else {
//                return
//            }
//            self?.tableView.reloadData()
//            self?.inputTextField.text = nil
//            self?.view.endEditing(true)
//        })
        
        dismiss(animated: true, completion: nil)
    }

    
    func handleSend() {
       
        // TODO
//        conversation?.sendText(inputTextField.text!, completion: {[weak self] (error) in
//            guard let _ = error else {
//                return
//            }
//            self?.tableView.reloadData()
//            self?.inputTextField.text = nil
//            self?.view.endEditing(true)
//        })

    }
    
    func handleKeyboardWillShow(_ notification: Notification) {
        let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        
        bottomLayoutContraint?.constant = -keyboardFrame!.height
       
        UIView.animate(withDuration: keyboardDuration!, animations: view.layoutIfNeeded)
    }
    
    func handleKeyboardWillHide(_ notification: Notification) {
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        
        bottomLayoutContraint?.constant = 0

        UIView.animate(withDuration: keyboardDuration!, animations: view.layoutIfNeeded)
    }
    
    
    private func handleTypingChangedEvent(member: NXMMember, isTyping: Bool) {
        /* make sure it is not this user typing */
//        if !member.user.isMe {
//            let name = member.user.name
//
//            if isTyping {
//                whoIsTyping.insert(name)
//            } else {
//                whoIsTyping.remove(name)
//            }
//
//            refreshTypingIndicatorLabel()
//        }
    }
    
    func refreshTypingIndicatorLabel(){
        if !whoIsTyping.isEmpty {
            var caption = whoIsTyping.joined(separator: ", ")
            
            if whoIsTyping.count == 1 {
                caption += " is typing..."
            } else {
                caption += " are typing..."
            }
            
            DispatchQueue.main.async { [weak self] in
                print(caption)
                self?.isTypingLabel.text = caption
            }
            
            
        } else {
            
            DispatchQueue.main.async { [weak self] in
                self?.isTypingLabel.text = ""
            }
        }
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "getInfo" {
            let destinationNavigationController = segue.destination as! ConversationInfoViewController
            destinationNavigationController.conversation = conversation
        } else if segue.identifier == "photoViewer" {
//            let row = (sender as! IndexPath).row
//            guard let imageEvent = conversation?.events[row] as? ImageEvent, let imagePath = imageEvent.path(of: IPS.ImageType.original) else {
//                return
//            }
//            let destinationNavigationController = segue.destination as! UINavigationController
//            let targetController = destinationNavigationController.topViewController as! PhotoViewController
//            targetController.image = UIImage(contentsOfFile: imagePath)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

extension ChatTableViewController: UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.conversationEvents.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = UIColor.white
        cell.imageView?.image = nil
        cell.accessoryType = UITableViewCellAccessoryType.none
        
        let event = self.conversationEvents[indexPath.row]

        switch event {
        case is NXMTextEvent:
            let textEvent = (event as! NXMTextEvent)
            cell.textLabel?.text = textEvent.text
            break
        case is NXMImageEvent:
            let imageEvent = (event as! NXMImageEvent)
            //TODO: crash
//            let imageURL = imageEvent.thumbnailImage.url
//            cell.imageView?.sd_setImage(with: imageURL as URL, placeholderImage: nil, options: [], progress: nil, completed: nil)
            break
            

        case is NXMMediaEvent:
            let mediaEvent = (event as! NXMMediaEvent)
            let isAudioEnabled = mediaEvent.mediaSettings.isEnabled
            if let member = memberLookup[event.fromMemberId] {
                cell.textLabel?.text =  member.name + " " + (isAudioEnabled ? "enabled audio" : "disabled audio")
            }
            break
        case is NXMMemberEvent:
            let memberEvent = (event as! NXMMemberEvent)
            var statusString:String?

            switch memberEvent.state {
            case .invited:
                statusString = "invited"
                break
            case .joined:
                statusString = "joined"
                break
            case .left:
                statusString = "left"
            }
            if let member = memberLookup[event.fromMemberId] {
                cell.textLabel?.text = member.name + " " + statusString!
            }
//            cell.textLabel?.text =  (memberEvent.from?.name)! + " joined"
            break
        default:
            cell.textLabel?.text = ""
        }
        //TODO stylize message status
        var statusStr = ""
        if self.conversationMessageStatuses[event.sequenceId] != nil {
            let status = self.conversationMessageStatuses[event.sequenceId] as! NXMMessageStatusType
            switch status {
            case .seen:
                statusStr = "Seen"
                break
            case .none:
                statusStr = "none"
                break
            case .delivered:
                statusStr = "delivered"
                break
            case .deleted:
                statusStr = "deleted"
                break
            }
        }
        
        if let member = memberLookup[event.fromMemberId] {
            cell.detailTextLabel?.text = statusStr + " " + member.name + " " + event.creationDate.description
        }
        

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let event = conversation?.events[indexPath.row]
//        tableView.deselectRow(at: indexPath, animated: false)
//        if event is ImageEvent {
//            performSegue(withIdentifier: "photoViewer", sender: indexPath)
//        }
    }
}


class ContainerViewController:UIViewController {
    
    @IBOutlet weak var typingLabel: UILabel!
    @IBAction func sendAction(_ sender: Any) {
    }
    @IBAction func choosePhotoAction(_ sender: Any) {
    }
    @IBOutlet weak var textField: UITextField!
    
}
