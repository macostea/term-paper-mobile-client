//
//  AdvertiseViewController.swift
//  TermPaperMobile
//
//  Created by Mihai Costea on 31/03/15.
//  Copyright (c) 2015 Mihai Costea. All rights reserved.
//

import UIKit
import SwiftSpinner
import MultipeerConnectivity
import SwiftyJSON

private let transferServiceType = "tpmc-transfer"

class AdvertiseViewController: UIViewController, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate {

    var advertisier: MCNearbyServiceAdvertiser?
    var localPeerID: MCPeerID?
    var mcSession: MCSession?
    
    var account: Account?
    
    var connectedPeer: MCPeerID?

    override func viewDidLoad() {
        super.viewDidLoad()

        SwiftSpinner.show("Waiting for request...")
        self.initMultipeerConnection()
    }
    
    // MARK:- Multipeer
    
    //TODO: Move all this in TransactionRelay
    
    private func initMultipeerConnection() {
        if let user = LoginManager.sharedInstance.currentUser {
            self.localPeerID = MCPeerID(displayName: user.name)
            self.mcSession = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: .Required)
            self.mcSession?.delegate = self
            
            self.advertisier = MCNearbyServiceAdvertiser(peer: localPeerID, discoveryInfo: nil, serviceType: transferServiceType)
            self.advertisier!.delegate = self
            self.advertisier?.startAdvertisingPeer()
        } else {
            SwiftSpinner.show("An error occoured", animated: false)
        }
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {
        invitationHandler(true, self.mcSession)
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didNotStartAdvertisingPeer error: NSError!) {
        println(error)
    }
    
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        
        println("Peer with id: \(peerID) changed state to \(state.rawValue)")
        
        switch state {
        case .NotConnected:
            SwiftSpinner.hide()
        case .Connected:
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                SwiftSpinner.show("Connected", animated: false)
            })

            self.connectedPeer = peerID
            
            self.sendAccountId()
        case .Connecting:
            println() //do nothing
        }
    }
    
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
        
    }
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
        
    }
    
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        var error: NSError?
        let dict = NSJSONSerialization.JSONObjectWithData(data, options: .allZeros, error: &error) as [String: AnyObject]
        
        if error != nil {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                SwiftSpinner.show("Error getting transaction", animated: false)
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), { () -> Void in
                    SwiftSpinner.hide()
                })
            })
            return
        }
        
        if let transactionDict = dict["transaction"] as? [String: AnyObject] {
            if let transaction = Transaction(json: JSON(transactionDict)) {
                println(transaction)
            
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    SwiftSpinner.show("Transaction complete", animated: false)
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), { () -> Void in
                        SwiftSpinner.hide()
                    })
                })
            }
        }

    }
    
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
        
    }
    
    func sendAccountId() {
        if let connectedPeerID = self.connectedPeer {
            SwiftSpinner.show("Sending transaction details...", animated: true)
            
            var error: NSError?
            
            var dict = ["destinationAccount": self.account!.toDict()]
            
            var data = NSJSONSerialization.dataWithJSONObject(dict, options: .allZeros, error: &error)
            
            if error != nil {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    println(error)
                    SwiftSpinner.show("Serialization error", animated: false)
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), { () -> Void in
                        SwiftSpinner.hide()
                    })
                })

                return
            }
            
            self.mcSession?.sendData(data, toPeers: [connectedPeerID], withMode: .Reliable, error: &error)
        }
    }
}
