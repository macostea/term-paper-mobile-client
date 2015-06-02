//
//  TransactionRelay.swift
//  TermPaperMobile
//
//  Created by Mihai Costea on 31/03/15.
//  Copyright (c) 2015 Mihai Costea. All rights reserved.
//

import Foundation
import SwiftyJSON

class TransactionRelay: NSObject {
    
    class func authorizeTransaction(transaction: Transaction, completionBlock: (Bool) -> Void) {
        if let token = LoginManager.sharedInstance.currentUser?.token {
            Router.sharedInstance.authorizeTransaction(token, parameters: transaction.transactionRelayDict(), completionBlock: { (json, error) -> Void in
                if let err = error {
                    println("Failed to authorize transaction: \(err)")
                    completionBlock(false)
                    return
                }
                
                println(json)
                completionBlock(true)
            })
        }
    }
    
}