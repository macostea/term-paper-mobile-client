//
//  Router.swift
//  TermPaperMobile
//
//  Created by Mihai Costea on 23/03/15.
//  Copyright (c) 2015 Mihai Costea. All rights reserved.
//

import Foundation
import Alamofire

enum Router: URLRequestConvertible {
    static let baseURLString = "https://term-paper-backend.herokuapp.com/api"
//    static let baseURLString = "https://term-paper-backend-macostea.c9.io/api"
    
    case Login([String: AnyObject])
    case Accounts(String, String)
    case AuthorizeTransaction(String, [String: AnyObject])
    
    var method: Alamofire.Method {
        switch self {
        case .Login:
            return .POST
        case .Accounts:
            return .GET
        case .AuthorizeTransaction:
            return .POST
        }
    }
    
    var path: String {
        switch self {
        case .Login(_):
            return "/login"
        case .Accounts(_, let userId):
            return "/users/\(userId)/accounts"
        case .AuthorizeTransaction(_, _):
            return "/transactions"
        }
    }
    
    // MARK: URLRequestConvertible
    
    var URLRequest: NSURLRequest {
        let URL = NSURL(string: Router.baseURLString)!
        let mutableURLRequest = NSMutableURLRequest(URL: URL.URLByAppendingPathComponent(path))
        mutableURLRequest.HTTPMethod = method.rawValue
        
        switch self {
        case .Login(let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
        case .Accounts(let token, _):
            mutableURLRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            return mutableURLRequest
        case .AuthorizeTransaction(let token, let parameters):
            mutableURLRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
        default:
            return mutableURLRequest
        }
    }
}