//
//  ChatTableViewController.swift
//  Stitch-Demo
//
//  Created by Tony Hung on 6/13/18.
//  Copyright © 2018 Nexmo. All rights reserved.
//

import UIKit
import StitchClient
class ChatTableViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    
    let client: NXMStitchClient = {
        return NXMStitchClient.init()
    }()

    var conversation: NXMConversation?
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
        
        navigationItem.title = conversation?.name

        // Create the info button
        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(getInfo(_:)), for: .touchUpInside)
        let infoBarButtonItem = UIBarButtonItem(customView: infoButton)
        navigationItem.rightBarButtonItem = infoBarButtonItem
        

        inputTextField.becomeFirstResponder()
        tableView.keyboardDismissMode = .interactive
        
        setupKeyboardObservers()
    
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
        conversation?.sendAttachment(of: .image, withName: "My Image", data: data, completion: { [weak self] (error) in
            guard let _ = error else {
                return
            }
            self?.tableView.reloadData()
            self?.inputTextField.text = nil
            self?.view.endEditing(true)
        })
        
        dismiss(animated: true, completion: nil)
    }

    
    func handleSend() {
       
        // send metho
        conversation?.sendText(inputTextField.text!, completion: {[weak self] (error) in
            guard let _ = error else {
                return
            }
            self?.tableView.reloadData()
            self?.inputTextField.text = nil
            self?.view.endEditing(true)
        })

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
        return 0;//conversation!.events.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = UIColor.white
        cell.imageView?.image = nil
        cell.accessoryType = UITableViewCellAccessoryType.none

//        let event = conversation?.events[indexPath.row]
//
//        switch event {
//        case is ImageEvent:
//            let imageEvent = (event as! ImageEvent)
//            guard let imagePath = imageEvent.path(of: IPS.ImageType.thumbnail) else {
//                break
//            }
//            cell.imageView?.image = UIImage(contentsOfFile: imagePath)
//            cell.textLabel?.text = (imageEvent.from?.name)! + " uploaded a photo"
//            cell.detailTextLabel?.text = (event?.createDate.description)!
//            break
//        case is TextEvent:
//            let textEvent = (event as! TextEvent)
//            //TODO: Is this how we get the seen receipt?
//            let receipt = textEvent.receiptForMember(textEvent.fromMember!)
//            if (receipt != nil) {
//                if (receipt?.state == ReceiptRecord.State.seen) {
//                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
//                }
//            }
//            
//            cell.textLabel?.text = textEvent.text
//            cell.detailTextLabel?.text = (textEvent.from?.name)! + " " + (event?.createDate.description)!
//            break
//        case is MediaEvent:
//            let mediaEvent = (event as! MediaEvent)
//            
//            cell.textLabel?.text =  (mediaEvent.from?.name)! + " " + (mediaEvent.enabled ? "enabled audio" : "disabled audio")
//            cell.detailTextLabel?.text = mediaEvent.createDate.description
//            break
//        case is MemberJoinedEvent:
//            let memberJoinedEvent = (event as! MemberJoinedEvent)
//            cell.textLabel?.text =  (memberJoinedEvent.from?.name)! + " joined"
//            cell.detailTextLabel?.text = memberJoinedEvent.createDate.description
//            break
//        case is MemberInvitedEvent:
//            let memberInvited = (event as! MemberInvitedEvent)
//            cell.textLabel?.text =  (memberInvited.from?.name)! + " invited"
//            cell.detailTextLabel?.text = memberInvited.createDate.description
//            break
//        case is MemberLeftEvent:
//            let memberLeft = (event as! MemberLeftEvent)
//            cell.textLabel?.text =  (memberLeft.from?.name)! + " left"
//            cell.detailTextLabel?.text = memberLeft.createDate.description
//            break
//        default:
//            cell.textLabel?.text = ""
//        }

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
