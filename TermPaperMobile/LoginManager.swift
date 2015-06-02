//
//  LoginManager.swift
//  TermPaperMobile
//
//  Created by Mihai Costea on 26/03/15.
//  Copyright (c) 2015 Mihai Costea. All rights reserved.
//

import UIKit
import SwiftyJSON
import Box

private let _sharedLoginManager = LoginManager()

class LoginManager: NSObject {
    
    var currentUser: User?
    
    class var sharedInstance: LoginManager {
        return _sharedLoginManager
    }
    
    func loginUser(email: String, password: String, completionBlock: (result: Either<User, NSError>) -> Void) {
        var loginParams = ["email": email,
                           "password": password]
        Router.sharedInstance.login(loginParams, completionBlock: { (jsonData, error) -> Void in
            println(jsonData)
            
            if let err = error {
                completionBlock(result: .Error(Box<NSError>(err)))
                return
            }
            
            let loggedUser = User(json: jsonData!["user"], token: jsonData!["token"].string)
            self.currentUser = loggedUser
            completionBlock(result: .Result(Box<User>(loggedUser!)))
        })
    }
}
