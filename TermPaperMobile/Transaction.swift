//
//  Transaction.swift
//  TermPaperMobile
//
//  Created by Mihai Costea on 24/03/15.
//  Copyright (c) 2015 Mihai Costea. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Transaction: Printable {
    let sourceAccount: Account
    let destinationAccount: Account
    let amount: Float
    
    // Printable
    var description: String {
        return "Source: \(self.sourceAccount)\nDestination: \(self.destinationAccount)\nAmount: \(self.amount)"
    }
}

extension Transaction {
    init?(json: JSON) {
        let sourceAccount = Account(json: json["source"])
        let destinationAccount = Account(json: json["destination"])
        
        if sourceAccount == nil || destinationAccount == nil {
            return nil
        }
        
        self.sourceAccount = sourceAccount!
        self.destinationAccount = destinationAccount!
        self.amount = json["amount"].floatValue
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["source"] = self.sourceAccount.toDict()
        dict["destination"] = self.destinationAccount.toDict()
        dict["amount"] = "\(self.amount)"
        
        return dict
    }
}