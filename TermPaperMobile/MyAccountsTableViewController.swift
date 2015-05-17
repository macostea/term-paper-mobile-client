//
//  MyAccountsTableViewController.swift
//  TermPaperMobile
//
//  Created by Mihai Costea on 24/03/15.
//  Copyright (c) 2015 Mihai Costea. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class MyAccountsTableViewController: UITableViewController {

    var accounts: [Account]?
    
    var amountTextField: UITextField?
    var amount: Float?
    var selectedAccount: Account?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.requestData()
    }
    
    // MARK: - Private
    
    func requestData() {
        
        if let user = LoginManager.sharedInstance.currentUser {
            SwiftSpinner.show("Getting accounts", animated: true)
            Alamofire.request(Router.Accounts(user.token!, user.userId)).responseJSON(options: .allZeros, completionHandler: { (request, response, jsonData, error) -> Void in
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
                    if let account = Account(json: accountJSON.1) {
                        accounts.append(account)
                    }
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
        let cell = tableView.dequeueReusableCellWithIdentifier("accountCell", forIndexPath: indexPath) as! UITableViewCell

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
                
                let amountController = UIAlertController(title: "Amount", message: "Select amount to send", preferredStyle: UIAlertControllerStyle.Alert)
                amountController.addTextFieldWithConfigurationHandler({ (textField) -> Void in
                    textField.placeholder = "Amount"
                    textField.keyboardType = .NumberPad
                    self.amountTextField = textField
                })
                amountController.addAction(UIAlertAction(title: "Send", style: .Default, handler: { (action) -> Void in
                    if let amountTextField = self.amountTextField {
                        let numberFormatter = NSNumberFormatter()
                        self.amount = numberFormatter.numberFromString(amountTextField.text)?.floatValue
                        self.selectedAccount = account
                        self.performSegueWithIdentifier("showPeersViewController", sender: nil)
                    }
                }))
                amountController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action) -> Void in
                }))
                
                self.presentViewController(amountController, animated: true, completion: nil)
            }))
            
            alertController.addAction(UIAlertAction(title: "Receive in this account", style: .Default, handler: { (action) -> Void in
                self.selectedAccount = account
                self.performSegueWithIdentifier("showAdvertiseViewController", sender: nil)
            }))
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action) -> Void in
            }))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func cancelSelection(segue: UIStoryboardSegue) {
        
    }
    
    // MARK:- Navigation
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        if identifier == "showPeersViewController" {
            if let amount = self.amount {
                if let selectedAccount = self.selectedAccount {
                    return true
                }
            }
            
            return false
        } else if identifier == "showAdvertiseViewController" {
            if let selectedAccount = self.selectedAccount {
                return true
            }
            return false
        }
        
        return false
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showPeersViewController" {
            if let amount = self.amount {
                let selectPeersNavigationController = segue.destinationViewController as! UINavigationController
                let selectPeersViewController = selectPeersNavigationController.viewControllers[0] as! SelectPeersViewController
                selectPeersViewController.amount = amount
                
                if let selectedAccount = self.selectedAccount {
                    selectPeersViewController.account = selectedAccount
                } else {
                }
            }
        } else if segue.identifier == "showAdvertiseViewController" {
            let advertiseNavigationController = segue.destinationViewController as! UINavigationController
            let advertiseViewController = advertiseNavigationController.viewControllers[0] as! AdvertiseViewController
            if let selectedAccount = self.selectedAccount {
                advertiseViewController.account = selectedAccount
            }
        }
    }
}
