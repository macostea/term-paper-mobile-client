//
//  Router.swift
//  TermPaperMobile
//
//  Created by Mihai Costea on 23/03/15.
//  Copyright (c) 2015 Mihai Costea. All rights reserved.
//

import Foundation
import SwiftyJSON
import CryptoSwift

private let baseURLString = "https://secure-transfer.tutora.ro/api"
private let EXPECTED_CERTIFICATE_SHA256 = "szarJiMbSbl6Id9MojN376C4lEtxJFffTFXMFBjNfg4="

//private let baseURLString = "https://term-paper-backend.herokuapp.com/api"
//private let baseURLString = "https://term-paper-backend-macostea.c9.io/api"

private let _sharedRouter = Router()

class Router: NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate {

    private var session: NSURLSession!
    
    class var sharedInstance: Router {
        return _sharedRouter
    }
    
    required override init() {
        super.init()
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.TLSMinimumSupportedProtocol = kTLSProtocol12
        
        self.session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    func login(parameters:[String: AnyObject], completionBlock:((JSON?, NSError?) -> Void)) {
        let request = NSMutableURLRequest(URL: NSURL(string: "\(baseURLString)/login")!)
        request.HTTPMethod = "POST"
        var err: NSError?
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(parameters, options: .allZeros, error: &err)!
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if (err != nil) {
            println(err)
            completionBlock(nil, err)
            return
        }
        
        self.makeRequest(request, completionBlock: completionBlock)
    }
    
    func accounts(token: String, userId: String, completionBlock:((JSON?, NSError?) -> Void)) {
        let request = NSMutableURLRequest(URL: NSURL(string: "\(baseURLString)/users/\(userId)/accounts")!)
        request.HTTPMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        self.makeRequest(request, completionBlock: completionBlock)
    }
    
    func authorizeTransaction(token: String, parameters: [String: AnyObject], completionBlock:((JSON?, NSError?) -> Void)) {
        let request = NSMutableURLRequest(URL: NSURL(string: "\(baseURLString)/transactions")!)
        request.HTTPMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var err: NSError?
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(parameters, options: .allZeros, error: &err)!
        
        if (err != nil) {
            println(err)
            completionBlock(nil, err)
            return
        }
        
        self.makeRequest(request, completionBlock: completionBlock)
    }
    
    //MARK:- NSURLSessionDelegate
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void) {
        let sender = challenge.sender
        let protectionSpace = challenge.protectionSpace
        
        if (protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) { // Self signed certificate on server
            if (self.shouldTrustProtectionSpace(protectionSpace)) {
                let trust = protectionSpace.serverTrust
                let certificate = SecTrustGetCertificateAtIndex(trust, 0)
                
                let serverCertificateData = SecCertificateCopyData(certificate.takeRetainedValue()).takeRetainedValue() as NSData
                
                let certPath = NSBundle.mainBundle().pathForResource("serverCert", ofType: "der")
                let certData = NSData(contentsOfFile: certPath!)!
                
                let certificatesEqual = serverCertificateData.isEqualToData(certData)
                
                if (certificatesEqual) {
                    let credential = NSURLCredential(trust: trust)
                    sender.useCredential(credential, forAuthenticationChallenge: challenge)
                    completionHandler(.UseCredential, credential)
                } else {
                    sender.cancelAuthenticationChallenge(challenge)
                    completionHandler(.CancelAuthenticationChallenge, nil)
                }
            } else {
                sender.cancelAuthenticationChallenge(challenge)
                completionHandler(.CancelAuthenticationChallenge, nil)
            }
        } else {
            // Client trust
            let path = NSBundle.mainBundle().pathForResource("term-paper-ca", ofType: "p12")
            let data = NSData(contentsOfFile: path!)!
            
            var myIdentity: SecIdentityRef?
            var myTrust: SecTrustRef?
            var myCertChain: [SecCertificateRef]?
            
            let status = extractIdentityAndTrust(data, identity: &myIdentity, trust: &myTrust, certChain: &myCertChain)
            
            var myCertificate: Unmanaged<SecCertificateRef>?
            SecIdentityCopyCertificate(myIdentity, &myCertificate)
            
            let credential = NSURLCredential(identity: myIdentity!, certificates: [myCertificate!.takeRetainedValue()], persistence: .Permanent)
            sender.useCredential(credential, forAuthenticationChallenge: challenge)
            completionHandler(.UseCredential, credential)
        }
    }
    
    //MARK:- Private
    
    private func makeRequest(request: NSURLRequest, completionBlock: ((JSON?, NSError?) -> Void)) {
        let task = self.session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                println(error)
                completionBlock(nil, error)
                return
            }
            
            var err: NSError?
            
            let json = JSON(data: data, options: NSJSONReadingOptions.AllowFragments, error: &err)
            
            if (err != nil) {
                println(err)
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionBlock(nil, err)
                })
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completionBlock(json, nil)
            })
        })
        
        task.resume()
    }
    
    private func shouldTrustProtectionSpace(protectionSpace: NSURLProtectionSpace) -> Bool {
        let certPath = NSBundle.mainBundle().pathForResource("serverCert", ofType: "der")
        let certData = NSData(contentsOfFile: certPath!)!
        
        var cert = SecCertificateCreateWithData(nil, certData).takeRetainedValue()
        var coll = Array<SecCertificate>()
        coll.append(cert)
        
        let serverTrust = protectionSpace.serverTrust
        SecTrustSetAnchorCertificates(serverTrust, coll)
        
        var trustResult: SecTrustResultType = 0
        SecTrustEvaluate(serverTrust, &trustResult)
        
        if (trustResult == UInt32(kSecTrustResultRecoverableTrustFailure)) {
            let errDataRef = SecTrustCopyExceptions(serverTrust)
            SecTrustSetExceptions(serverTrust, errDataRef.takeRetainedValue())
            SecTrustEvaluate(serverTrust, &trustResult)
        }
        
        return trustResult == UInt32(kSecTrustResultUnspecified) || trustResult == UInt32(kSecTrustResultProceed)
    }
    
}
