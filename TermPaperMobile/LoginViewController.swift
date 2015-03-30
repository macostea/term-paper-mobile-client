//
//  LoginViewController.swift
//  TermPaperMobile
//
//  Created by Mihai Costea on 23/03/15.
//  Copyright (c) 2015 Mihai Costea. All rights reserved.
//

import UIKit
import SwiftSpinner
import Alamofire
import SwiftyJSON

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func loginButtonPressed() {
        if let email = self.emailTextField.text {
            if let password = self.passwordTextField.text {
                SwiftSpinner.show("Working...")
                LoginManager.sharedInstance.loginUser(email, password: password, completionBlock: { (result) -> Void in
                    switch result {
                    case let .Error(err):
                        println(err())
                        SwiftSpinner.show("Login failed", animated: false)
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), { () -> Void in
                            SwiftSpinner.hide()
                        })
                        
                    case let .Result(res):
                        let appDelegate = UIApplication.sharedApplication().delegate
                        
                        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
                        let navigationController = storyboard.instantiateViewControllerWithIdentifier("myAccountsNavigationController") as UINavigationController
                        
                        let accountsViewController = navigationController.viewControllers![0] as MyAccountsTableViewController
                        
                        appDelegate!.window!?.rootViewController = navigationController
                    }
                })
            }
        }
    }
}
