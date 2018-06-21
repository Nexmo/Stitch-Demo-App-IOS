//
//  CallViewController.swift
//  Stitch-Demo
//
//  Created by Tony Hung on 6/21/18.
//  Copyright © 2018 Tony Hung. All rights reserved.
//

import UIKit
import Stitch

class CallViewController: UIViewController {

    
    /// Nexmo Conversation client
    let client: ConversationClient = {
        return ConversationClient.instance
    }()
    
    
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    
    
    var caller:String? {
        didSet {
            self.callUser(caller!)
        }
    }
    var call:Call? {
        didSet {
            setup()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action:  #selector(close(_:)))
        self.stateLabel.text = ""
        
        //TODO: add hangup button
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        print("auto hangup")
        self.hangup()
        call?.memberState.unsubscribe()
        call?.state.unsubscribe()
    }
    
    @objc func close(_ sender:UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    func callUser(_ user:String) {
        self.userLabel.text = "Calling " + user
        client.media.call([user], onSuccess: { [weak self] result in
            self?.call = result.call
            }, onError: { error in
                print("callUser", error)
                self.userLabel.text = "Call failed to " + user
        })
    }

    private func setup() {
        guard let call = call else {
            return
        }
        
        call.memberState.subscribe { [weak self] event in
            DispatchQueue.main.async {

                var message = self?.stateLabel.text
                
                switch event {
                case .ringing(let member):
                    message = ("Call: member ringing by: \(member.user.name)")
                case .answered(let member):
                    message = ("Call: member answered by: \(member.user.name)")
                    
                    message = message?.replacingOccurrences(of: "\(member.user.name)[rejected]", with: member.user.name)
                    message = message?.replacingOccurrences(of: "\(member.user.name)[hangUp]", with: member.user.name)
                    message = message?.replacingOccurrences(
                        of: member.user.name,
                        with: member.user.name + "[answered]"
                    )
                case .rejected(let member):
                    print("Call: member rejected by: \(member.user.name)")
                    
                    message = message?.replacingOccurrences(of: "\(member.user.name)[answered]", with: member.user.name)
                    message = message?.replacingOccurrences(of: "\(member.user.name)[hangUp]", with: member.user.name)
                    message = message?.replacingOccurrences(
                        of: member.user.name,
                        with: member.user.name + "[rejected]"
                    )
                case .hangUp(let member):
                    print("DEMO - Call: member \(member.user.name) hangup")
                    
                    guard self?.call?.to.contains(where: { $0.state == .joined || $0.state == .invited }) == true else {
                        print("DEMO - Will auto hang up as all other participants have hung up")
                        
                        self?.hangup()
                        
                        return
                    }
                    
                    message = message?.replacingOccurrences(of: "\(member.user.name)[answered]", with: member.user.name)
                    message = message?.replacingOccurrences(of: "\(member.user.name)[rejected]", with: member.user.name)
                    message = message?.replacingOccurrences(
                        of: member.user.name,
                        with: member.user.name + "[hangUp]"
                    )
                }
                
                self?.stateLabel.text = message
            }
        }
    }
    
    func hangup() {
        guard let call = call else {
            return
        }
        
        call.hangUp(onSuccess: {
        }, onError: { [weak self] error in
            print("Failed to hangup call: \(error.localizedDescription)")
        })
        
        dismiss(animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
