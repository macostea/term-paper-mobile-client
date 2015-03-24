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
    
    case CreateExpense([String: AnyObject])
    case GetExpense(String)
    case GetAll
    case UpdateExpense(String, [String: AnyObject])
    case DeleteExpense([String: AnyObject])
    
    case Login([String: AnyObject])
    case Accounts(String)
    
    var method: Alamofire.Method {
        switch self {
        case .CreateExpense:
            return .POST
        case .GetExpense:
            return .GET
        case .GetAll:
            return .GET
        case .UpdateExpense:
            return .PUT
        case .DeleteExpense:
            return .DELETE
        case .Login:
            return .POST
        case .Accounts:
            return .GET
        }
    }
    
    var path: String {
        switch self {
        case .CreateExpense:
            return "/expenses"
            
        case .GetExpense(let expenseId):
            return "/expenses/\(expenseId)"
            
        case .GetAll:
            return "/expenses"
            
        case UpdateExpense(let expenseId, _):
            return "/expenses/\(expenseId)"
            
        case .DeleteExpense(let expenseId):
            return "/expenses/\(expenseId)"
            
        case .Login(_):
            return "/login"
        case .Accounts(let userId) :
            return "/users/\(userId)/accounts"
        }
    }
    
    // MARK: URLRequestConvertible
    
    var URLRequest: NSURLRequest {
        let URL = NSURL(string: Router.baseURLString)!
        let mutableURLRequest = NSMutableURLRequest(URL: URL.URLByAppendingPathComponent(path))
        mutableURLRequest.HTTPMethod = method.rawValue
        
        switch self {
        case .CreateExpense(let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
        case .UpdateExpense(_, let parameters):
            return Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: parameters).0
        case .Login(let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
        default:
            return mutableURLRequest
        }
    }
}