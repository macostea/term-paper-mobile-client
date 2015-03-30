//
//  User.swift
//  TermPaperMobile
//
//  Created by Mihai Costea on 23/03/15.
//  Copyright (c) 2015 Mihai Costea. All rights reserved.
//

import Foundation
import SwiftyJSON

struct User: Printable {
    let email: String
    let userId: String
    let name: String
    let token: String?
    
    let accounts: [AnyObject]?
    
    // Printable
    
    var description: String {
        return "UserId: \(self.userId)\nName: \(self.name)\nEmail: \(self.email)\nAccounts: \(self.accounts)"
    }
}

extension User {
    init?(json: JSON, token: String?) {
        if token == nil {
            return nil
        }
        
        self.userId = json["_id"].stringValue
        self.email = json["email"].stringValue
        self.name = json["name"].stringValue
        self.accounts = json["accounts"].arrayObject
        self.token = token
    }
}
