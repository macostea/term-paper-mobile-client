//
//  SelectPeersViewController.swift
//  TermPaperMobile
//
//  Created by Mihai Costea on 30/03/15.
//  Copyright (c) 2015 Mihai Costea. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import SwiftyJSON

private let transferServiceType = "tpmc-transfer"

class SelectPeersViewController: UITableViewController, MCNearbyServiceBrowserDelegate ,MCSessionDelegate {
    
    var advertisier: MCNearbyServiceAdvertiser?
    var browser: MCNearbyServiceBrowser?
    var timeStartedAdvertising: NSDate?
    var localPeerID: MCPeerID?
    var mcSession: MCSession?
    
    var amount: Float?
    var account: Account?
    var destinationAccount: Account?
    
    var peers = [MCPeerID]()
    
    var connectedPeer: MCPeerID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initMultipeerSession()
        
    }
    
// MARK:- UITableView methods

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.peers.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("peersCell") as! UITableViewCell
        let peer = self.peers[indexPath.row]
        cell.textLabel?.text = peer.displayName
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let peer = self.peers[indexPath.row]
        
        let alertController = UIAlertController(title: "Send", message: "Are you sure you want to send \(self.amount!) to \(peer.displayName)?", preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action) -> Void in
            SwiftSpinner.show("Connecting...", animated: true)
            self.browser!.invitePeer(peer, toSession: self.mcSession, withContext: nil, timeout: 30)
        }))
        alertController.addAction(UIAlertAction(title: "No", style: .Cancel, handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
// MARK:- Multipeer Coonectivity
    
    func initMultipeerSession() {
        if let user = LoginManager.sharedInstance.currentUser {
            self.localPeerID = MCPeerID(displayName: user.name)
            
            let path = NSBundle.mainBundle().pathForResource("multipeer", ofType: "p12")
            let data = NSData(contentsOfFile: path!)!
            
            var myIdentity: SecIdentityRef?
            var myTrust: SecTrustRef?
            var myCertChain: [SecCertificateRef]?
            
            let status = extractIdentityAndTrust(data, identity: &myIdentity, trust: &myTrust, certChain: &myCertChain)
            
            self.mcSession = MCSession(peer: self.localPeerID, securityIdentity: [myIdentity!], encryptionPreference: .Required)
            self.mcSession?.delegate = self
            
            self.browser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: transferServiceType)
            self.browser!.delegate = self
            self.browser?.startBrowsingForPeers()
        }
    }
    
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        if (!contains(self.peers, peerID)) {
            self.peers.append(peerID)
            self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.peers.count-1, inSection: 0)], withRowAnimation: .Automatic)
        }
    }
    
    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
        if let position = find(self.peers, peerID) {
            self.peers.removeAtIndex(position)
            self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: position, inSection: 0)], withRowAnimation: .Automatic)
        }
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
        let dict = NSJSONSerialization.JSONObjectWithData(data, options: .allZeros, error: &error) as! [String: AnyObject]
        
        if error != nil {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                SwiftSpinner.show("Error getting destination account", animated: false)
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), { () -> Void in
                    SwiftSpinner.hide()
                })
            })
            
            return
        }
        
        if let destinationAccountDict = dict["destinationAccount"] as? [String: AnyObject] {
            if let account = Account(json: JSON(destinationAccountDict)) {
                println(account)
                
                self.destinationAccount = account
                self.sendTransaction()
            } else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    SwiftSpinner.show("Corrupted destination account", animated: false)
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), { () -> Void in
                        SwiftSpinner.hide()
                    })
                })
            }
        }
    }
    
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
        
    }
    
    func session(session: MCSession!, didReceiveCertificate certificate: [AnyObject]!, fromPeer peerID: MCPeerID!, certificateHandler: ((Bool) -> Void)!) {
        let cert = certificate[0] as! SecCertificateRef
        let certData = SecCertificateCopyData(cert)
        
        let path = NSBundle.mainBundle().pathForResource("multipeer", ofType: "p12")
        let data = NSData(contentsOfFile: path!)!
        
        var myIdentity: SecIdentityRef?
        var myTrust: SecTrustRef?
        var myCertChain: [SecCertificateRef]?
        
        let status = extractIdentityAndTrust(data, identity: &myIdentity, trust: &myTrust, certChain: &myCertChain)
        
        let myCert = myCertChain![0]
        let myCertData = SecCertificateCopyData(myCert)
        
        if (certData.takeRetainedValue() as NSData).isEqualToData(myCertData.takeRetainedValue() as NSData) {
            certificateHandler(true)
        } else {
            certificateHandler(false)
        }
    }
    
    func sendTransaction() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            SwiftSpinner.show("Sending...", animated: true)
        })
        
        if let sourceAccount = self.account {
            if let destinationAccount = self.destinationAccount {
                if let amount = self.amount {
                    if let peer = self.connectedPeer {
                        let transaction = Transaction(sourceAccount: sourceAccount, destinationAccount: destinationAccount, amount: amount)
                        let transactionDict = ["transaction": transaction.toDict()]
                        
                        var error: NSError?
                        
                        let transactionData = NSJSONSerialization.dataWithJSONObject(transactionDict, options: .allZeros, error: &error)
                        
                        if error != nil {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                println(error)
                                SwiftSpinner.show("Error sending transaction", animated: false)
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), { () -> Void in
                                    SwiftSpinner.hide()
                                })
                            })
                            return
                        }
                        
                        self.mcSession?.sendData(transactionData, toPeers: [peer], withMode: .Reliable, error: &error)
                        
                        if error != nil {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                println(error)
                                SwiftSpinner.show("Error sending transaction", animated: false)
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), { () -> Void in
                                    SwiftSpinner.hide()
                                })
                            })
                        } else {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                SwiftSpinner.show("Transaction sent", animated: false)
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), { () -> Void in
                                    SwiftSpinner.hide()
                                    self.dismissViewControllerAnimated(true, completion: nil)
                                })
                            })
                        }
                        return
                    }
                }
            }
        }

        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            SwiftSpinner.show("Something went wrong", animated: true)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), { () -> Void in
                SwiftSpinner.hide()
            })
        })
    }
}
