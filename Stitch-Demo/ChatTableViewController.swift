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
    var memberId:String?
    
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
        ConversationManager.shared.client.setDelgate(self)
        
        ConversationManager.shared.client.getConversationDetails((conversation?.uuid)!, onSuccess: { (conversationDetails) in
            for member in conversationDetails!.members {
                print(member)
                if member.name == ConversationManager.shared.currentUser?.name {
                    self.memberId = member.memberId
                }
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
        guard let message = inputTextField.text, let conv_uuid = self.conversation?.uuid, let fromMemberId = self.memberId else {
            return
        }
        ConversationManager.shared.client.sendText(message, conversationId: conv_uuid, fromMemberId: fromMemberId, onSuccess: { (success) in
            DispatchQueue.main.async { [weak self] in
                self!.inputTextField.text = ""
            }
        }) { (error) in
            print(error)
        }
    }
    
    func setupKeyboardObservers() {
       
    }
    func addObservers() {
//        NotificationCenter.default.add
    }
    
    //MARK: TextField Delegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let conv_uuid = self.conversation?.uuid, let fromMemberId = self.memberId else {
            return true
        }
        ConversationManager.shared.client.startTyping(conv_uuid, memberId: fromMemberId, onSuccess: {
            print("success")
        }) { (error) in
            print(error)
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let conv_uuid = self.conversation?.uuid, let fromMemberId = self.memberId else {
            return true
        }
        ConversationManager.shared.client.stopTyping(conv_uuid, memberId: fromMemberId, onSuccess: {
            print("success")
        }) { (error) in
            print(error)
        }
        return true
    }
    
    //Mark UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage, let data = UIImagePNGRepresentation(image), let conv_uuid = self.conversation?.uuid, let fromMemberId = self.memberId  else {
            return
        }
        let filename = UUID().uuidString
        ConversationManager.shared.client.sendImage(withName: "\(filename).png", image: data, conversationId: conv_uuid, fromMemberId: fromMemberId, onSuccess: { [weak self] (success) in
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
                self?.inputTextField.text = nil
                self?.view.endEditing(true)
            }
        }) { [weak self] (error) in
            print(error)
            self?.inputTextField.text = nil
            self?.view.endEditing(true)
        }
        
        dismiss(animated: true, completion: nil)
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
        
        //Mark cell's as `seen` by showing a checkmark
        cell.accessoryType = .none
        if self.conversationMessageStatuses[event.sequenceId] != nil {
            let status = self.conversationMessageStatuses[event.sequenceId]
            if status == .seen {
                cell.accessoryType = .checkmark
            }
        }
        
        if let member = memberLookup[event.fromMemberId] {
            cell.detailTextLabel?.text = member.name + " " + event.creationDate.description
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

extension ChatTableViewController:NXMStitchCoreDelegate {
    func connectionStatusChanged(_ isOnline: Bool) {
        
    }
    
    func loginStatusChanged(_ user: NXMUser?, loginStatus isLoggedIn: Bool, withError error: Error?) {
        
    }
    
    func memberJoined(_ memberEvent: NXMMemberEvent) {
        
    }
    
    func memberInvited(_ memberEvent: NXMMemberEvent) {
        
    }
    
    func memberRemoved(_ memberEvent: NXMMemberEvent) {
        
    }
    
    func textRecieved(_ textEvent: NXMTextEvent) {
        
        if textEvent.conversationId != self.conversation?.uuid {
            return
        }
        
        if self.conversationEvents.filter({ $0.sequenceId == textEvent.sequenceId }).count == 0 {
            self.conversationEvents.append(textEvent)
            self.tableView.reloadData()
        }
        
        //TODO: mark textEvent as seen

    }
    
    func textDelivered(_ statusEvent: NXMMessageStatusEvent) {
        updateMessageStatus(statusEvent)
    }
    
    func textSeen(_ statusEvent: NXMMessageStatusEvent) {
        updateMessageStatus(statusEvent)
    }
    
    func messageDeleted(_ statusEvent: NXMMessageStatusEvent) {
        updateMessageStatus(statusEvent)
    }
    
    func imageSeen(_ statusEvent: NXMMessageStatusEvent) {
        updateMessageStatus(statusEvent)
    }
    
    func imageDelivered(_ statusEvent: NXMMessageStatusEvent) {
        updateMessageStatus(statusEvent)
    }
    
    func textTyping(on textTypingEvent: NXMTextTypingEvent) {
        
        if textTypingEvent.conversationId != self.conversation?.uuid {
            return
        }
        if textTypingEvent.fromMemberId == self.memberId {
            return
        }
        if textTypingEvent.status  == .off {
            self.isTypingLabel.isHidden = true
        }
        guard let member = memberLookup[textTypingEvent.fromMemberId] else {
            return
        }
        self.isTypingLabel.text = "\(member.name!) is typing"
        self.isTypingLabel.isHidden = false

    }
    
    func textTypingOff(_ textTypingEvent: NXMTextTypingEvent) {
        print("textTypingOff")
        self.isTypingLabel.isHidden = true
        
    }
    
    func imageRecieved(_ imageEvent: NXMImageEvent) {
        
    }
    
    //TODO: find better way than reloading data
    func updateMessageStatus(_ statusEvent: NXMMessageStatusEvent) {
        self.conversationMessageStatuses[statusEvent.eventId] = statusEvent.status
        self.tableView.reloadData()
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
