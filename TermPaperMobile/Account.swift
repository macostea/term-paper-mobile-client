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
    let accountId: String
    let status: String
    let currentFunds: Float
    let accountHolder: User?
    let pastTransactions: [Transaction]?
    
    // Printable
    
    var description: String {
        return "Status: \(self.status)\nCurrentFunds: \(self.currentFunds)\nHolder: \(self.accountHolder?.name)\nTransactions: \(self.pastTransactions)"
    }
}

extension Account {
    init(json: JSON) {
        self.status = json["status"].stringValue
        self.accountId = json["_id"].stringValue
        self.currentFunds = json["currentFunds"].floatValue
//        self.accountHolder = User(json: json["accountHolder"], token: nil)!
    }
}