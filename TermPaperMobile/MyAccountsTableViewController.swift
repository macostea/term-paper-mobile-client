//
//  MyAccountsTableViewController.swift
//  TermPaperMobile
//
//  Created by Mihai Costea on 24/03/15.
//  Copyright (c) 2015 Mihai Costea. All rights reserved.
//

import UIKit
import Alamofire
import SwiftSpinner
import SwiftyJSON

class MyAccountsTableViewController: UITableViewController {

    var accounts: [Account]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.requestData()
    }
    
    // MARK: - Private
    
    func requestData() {
        
        if let user = LoginManager.sharedInstance.currentUser {
            SwiftSpinner.show("Getting accounts", animated: true)
            Alamofire.request(Router.Accounts(user.userId)).responseJSON({ (req, res, jsonData, error) -> Void in
                if let err = error {
                    println(err)
                    SwiftSpinner.show("Failed getting accounts", animated: false)
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), { () -> Void in
                        SwiftSpinner.hide()
                    })
                    return
                }
                let json = JSON(jsonData!)
                SwiftSpinner.hide()
                
                var accounts = [Account]()
                
                for accountJSON in json {
                    let account = Account(json: accountJSON.1)
                    accounts.append(account)
                }
                
                self.accounts = accounts
                self.tableView.reloadData()
            })
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let accounts = self.accounts {
            return accounts.count
        } else {
            return 0
        }

    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("accountCell", forIndexPath: indexPath) as UITableViewCell

        if let accounts = self.accounts {
            let account = accounts[indexPath.row]
            cell.textLabel?.text = account.accountId
            cell.detailTextLabel?.text = "\(account.currentFunds)"
        }

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let accounts = self.accounts {
            let account = accounts[indexPath.row]
            
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            alertController.addAction(UIAlertAction(title: "Send from this account", style: .Default, handler: { (action) -> Void in
                
            }))
            
            alertController.addAction(UIAlertAction(title: "Receive in this account", style: .Default, handler: { (action) -> Void in
                
            }))
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action) -> Void in
                self.dismissViewControllerAnimated(true, completion: nil)
            }))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
}
