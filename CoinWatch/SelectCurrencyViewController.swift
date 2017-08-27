//
//  SelectCurrencyViewController.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/26/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit

class SelectCurrencyViewController: UITableViewController {
    var currencies = Currency.all
    var selectedCurrency: Currency?
    
    var didSelectCurrency: ((Currency)->())?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //self.autoScrollToSelectinIfApplicable()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.currencies.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        if let c = tableView.dequeueReusableCell(withIdentifier: "CurrencyCell") {
            cell = c
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: "CurrencyCell")
        }
        
        let currency = self.currencies[indexPath.row]
        cell.accessoryType = currency == self.selectedCurrency ? .checkmark : .none
        cell.textLabel?.text = "\(currency.rawValue) (\(currency.symbol))"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var affectedInidexPaths = [IndexPath]()
        
        if self.currencies[indexPath.row] == self.selectedCurrency {
            return
        }
        
        if let selectedCurrency = self.selectedCurrency {
            if let selectedIndex = self.currencies.index(where: { $0 == selectedCurrency }) {
                affectedInidexPaths.append(IndexPath(row: selectedIndex, section: 0))
            }
        }
        
        self.selectedCurrency = self.currencies[indexPath.row]
        affectedInidexPaths.append(indexPath)
        tableView.reloadRows(at: affectedInidexPaths, with: .automatic)
        self.didSelectCurrency?(self.currencies[indexPath.row])        
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Select Currency"
    }
    
    
    // MARK: - misc
    private func autoScrollToSelectinIfApplicable() {
        guard let selectedCurrency = self.selectedCurrency else { return }
        if let index = self.currencies.index(where: { $0 == selectedCurrency }) {
            self.tableView.scrollToRow(at: IndexPath(row: index, section: 9), at: .top, animated: false)
        }
    }
    

}
