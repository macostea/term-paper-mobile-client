//
//  Utils.swift
//  catwalk15
//
//  Created by Mihai Costea on 10/10/14.
//  Copyright (c) 2014 mcostea. All rights reserved.
//

import Foundation
import Box

enum Either<T, U> {
    case Result(Box<T>)
    case Error(Box<U>)
}

func extractIdentityAndTrust(inP12data: CFDataRef, inout #identity: SecIdentityRef?, inout #trust: SecTrustRef?, inout #certChain: [SecCertificateRef]?) -> OSStatus {
    var securityError = errSecSuccess
    
    let password = "rate"
    var options = NSMutableDictionary()
    options.setObject(password, forKey: kSecImportExportPassphrase.takeRetainedValue() as String)
    
    var keyref: Unmanaged<CFArray>?
    
    securityError = SecPKCS12Import(inP12data, options, &keyref)
    
    if (securityError != 0) {
        println("Error importing pkcs12: \(securityError)")
    }
    
    var keychainArray = keyref!
    var identityDict: Dictionary<String, AnyObject> = (keychainArray.takeRetainedValue() as NSArray)[0] as! Dictionary<String, AnyObject>
    let identityKey = kSecImportItemIdentity.takeRetainedValue()
    identity = identityDict[identityKey as String] as! SecIdentityRef
    
    let trustKey = kSecImportItemTrust.takeRetainedValue()
    trust = identityDict[trustKey as String] as! SecTrustRef
    
    let certKey = kSecImportItemCertChain.takeRetainedValue()
    certChain = identityDict[certKey as String] as! [SecCertificateRef]
    
    return securityError
}
