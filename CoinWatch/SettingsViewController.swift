//
//  SettingsViewController.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 12/12/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {
    private var isEditingCurrency = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
            case .currency: return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
            case .currency:
                let clazz = self.isEditingCurrency ? SelectCurrencyTableCell.self : CurrencyTableViewCell.self
                let cell = tableView.dequeReusableCell(withType: clazz)
                cell.userPreferences = UserPreferences.current()
                return cell                
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
            case .currency: return "Currency"
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section)! {
            case .currency:
                self.isEditingCurrency = !self.isEditingCurrency
                tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
}

extension SettingsViewController {
    enum Section : Int {
        case currency = 0
    }
}
