//
//  Account.swift
//  TermPaperMobile
//
//  Created by Mihai Costea on 24/03/15.
//  Copyright (c) 2015 Mihai Costea. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Account: Printable {
    let accountId: String!
    let status: String!
    var currentFunds: Float!
    var accountHolder: User?
    var pastTransactions: [Transaction]?
    
    // Printable
    
    var description: String {
        return "Status: \(self.status)\nCurrentFunds: \(self.currentFunds)\nHolder: \(self.accountHolder?.name)\nTransactions: \(self.pastTransactions)"
    }
}

extension Account {
    init?(json: JSON) {
        if json["_id"].string == nil {
            return nil
        }
        
        status = json["status"].stringValue
        accountId = json["_id"].stringValue
        currentFunds = json["currentFunds"].floatValue
//        self.accountHolder = User(json: json["accountHolder"], token: nil)!

    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["status"] = self.status
        dict["_id"] = self.accountId
        dict["currentFunds"] = self.currentFunds
        
        return dict
    }
}