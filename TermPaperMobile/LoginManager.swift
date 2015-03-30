//
//  LoginManager.swift
//  TermPaperMobile
//
//  Created by Mihai Costea on 26/03/15.
//  Copyright (c) 2015 Mihai Costea. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

private let _sharedLoginManager = LoginManager()

class LoginManager: NSObject {
    
    var currentUser: User?
    
    class var sharedInstance: LoginManager {
        return _sharedLoginManager
    }
    
    func loginUser(email: String, password: String, completionBlock: (result: Either<User, NSError>) -> Void) {
        var loginParams = ["email": email,
                           "password": password]
        Alamofire.request(Router.Login(loginParams)).responseJSON({ (request, response, jsonData, error) -> Void in
            
            if let err = error {
                completionBlock(result: .Error(err))
                return
            }
            
            let json = JSON(jsonData!)
            
            let loggedUser = User(json: json["user"], token: json["token"].string)
            self.currentUser = loggedUser
            completionBlock(result: .Result(loggedUser!))
        })
    }
}
