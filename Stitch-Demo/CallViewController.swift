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
    
    
    @IBOutlet weak var memberStatus: UILabel!
    @IBOutlet weak var stateLabel: UILabel?
    
    var call:Call? {
        didSet {
            setup()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action:  #selector(close(_:)))
        stateLabel?.text = ""
        memberStatus?.text = ""
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        print("auto hangup")
        hangup()
        call?.memberState.unsubscribe()
        call?.state.unsubscribe()
    }
    
    @objc func close(_ sender:UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    private func setup() {
        guard let call = call else {
            return
        }
        let toUsers = call.to.map { $0.user.name }
        stateLabel?.text = "Call from \(call.from?.user.name ?? "Unknown" ) to \(toUsers)"

        call.state.subscribe { [weak self] state in
            var currentState: String {
                switch state {
                case .started: return "started"
                case .ringing: return "ringing"
                case .answered: return "answered"
                case .rejected: return "rejected"
                case .busy: return "busy"
                case .unanswered: return "unanswered"
                case .timeout: return "timeout"
                case .failed: return "failed"
                case .complete: return "completed"
                case .machine: return "detected answering machine"
                }
            }
            self?.stateLabel?.text = "Call \(currentState)"
        }
        
        call.memberState.subscribe { [weak self] event in
            DispatchQueue.main.async {

                var message = self?.memberStatus?.text
                
                switch event {
                case .ringing(let member):
                    message = ("Call: member ringing by: \(member.user.name)")
                case .answered(let member):
                    message = ("Call: member answered by: \(member.user.name)")
                case .rejected(let member):
                    message = ("Call: member rejected by: \(member.user.name)")
                case .hangUp(let member):
                    message = ("Call: call hungup by: \(member.user.name)")
                    if self?.call?.to.contains(where: { $0.state == .joined || $0.state == .invited }) == true {
                        //hangup when all other participants have hung up
                        self?.hangup()
                    }
                }
                self?.memberStatus?.text = message
            }
        }
    }
    
    func hangup() {
        guard let call = call else {
            return
        }
        
        call.hangUp(onSuccess: {
        }, onError: { error in
            print("Failed to hangup call: \(error.localizedDescription)")
        })
        
        dismiss(animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
