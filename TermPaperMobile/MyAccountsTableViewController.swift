//
//  MyAccountsTableViewController.swift
//  TermPaperMobile
//
//  Created by Mihai Costea on 24/03/15.
//  Copyright (c) 2015 Mihai Costea. All rights reserved.
//

import UIKit

class MyAccountsTableViewController: UITableViewController {

    var accounts: [Account]? {
        set(newValue) {
            self.accounts = newValue
            self.tableView.reloadData()
        }
        get {
            return self.accounts
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
}
