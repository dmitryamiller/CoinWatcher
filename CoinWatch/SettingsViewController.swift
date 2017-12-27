//
//  SettingsViewController.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 12/12/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit
import coinbase_official
import RealmSwift


class SettingsViewController: UITableViewController {
    private var isEditingCurrency = false
    
    fileprivate var coinbaseAccountsToken: NotificationToken?
    fileprivate var coinbaseAccounts = [CoinbaseAccount]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.observeCoinbaseAccountNotifications()
        DispatchQueue.main.async { [weak self] in
            self?.loadAndObserveCoinbaseAccounts()
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
            case .currency: return 1
            case .coinbase: return self.coinbaseAccounts.count + 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
            case .currency:
                let clazz = self.isEditingCurrency ? SelectCurrencyTableCell.self : CurrencyTableViewCell.self
                let cell = tableView.dequeReusableCell(withType: clazz)
                cell.userPreferences = UserPreferences.current()
                return cell
            case .coinbase:
                if indexPath.row >= self.coinbaseAccounts.count {
                    return tableView.dequeueReusableCell(withIdentifier: "CoinbaseAddAccountTableCell")!
                } else {
                    let cell = tableView.dequeReusableCell(withType: CoinbaseAccountTableCell.self)
                    cell.coinbaseAccount = self.coinbaseAccounts[indexPath.row]
                    return cell
                }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
            case .currency: return "Currency"
            case .coinbase: return "Coinbase Account"
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var affectedIndexPaths = [IndexPath]()
        switch Section(rawValue: indexPath.section)! {
            case .currency:
                self.isEditingCurrency = !self.isEditingCurrency
                affectedIndexPaths.append(indexPath)
            case .coinbase:
                if self.isEditingCurrency {
                    self.isEditingCurrency = false
                    affectedIndexPaths.append(IndexPath(row: 0, section: Section.currency.rawValue))
                }
                
                CoinbaseManager.instance.startAuthentication()                
                break            
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if affectedIndexPaths.count > 0 {
            tableView.reloadRows(at: affectedIndexPaths, with: .automatic)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let section = Section(rawValue: indexPath.section) else { return false }
        switch section {
            case .currency:
                return false
            case .coinbase:
                if indexPath.row >= self.coinbaseAccounts.count {
                    return false
                } else {
                    return true
                }
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else { return }
        
        switch section {
            case .currency:
                return
            case .coinbase:
                if indexPath.row >= self.coinbaseAccounts.count {
                    return
                } else {
                    let coinbaseAccount = self.coinbaseAccounts[indexPath.row]
                    self.delete(coinbaseAccount: coinbaseAccount)
                }
        }
    }
}

extension SettingsViewController {
    fileprivate func loadAndObserveCoinbaseAccounts() {
        let realm = try! Realm()
        self.coinbaseAccountsToken = realm.objects(CoinbaseAccount.self).addNotificationBlock { [weak self] changes in
            var reloadCoinbaseSection = false
            switch changes {
                case .initial(let coinbaseAccounts):
                    self?.coinbaseAccounts = coinbaseAccounts.toArray()
                    reloadCoinbaseSection = true
                case .update(let coinbaseAccounts, let deletions, let insertions, _):
                    if deletions.count > 0 || insertions.count > 0 {
                        self?.coinbaseAccounts = coinbaseAccounts.toArray()
                        reloadCoinbaseSection = true
                    }
                case .error:
                    break
            }
            
            if reloadCoinbaseSection {
                self?.tableView.reloadSections(IndexSet(integer: Section.coinbase.rawValue), with: .automatic)
            }
        }
    }
    
    fileprivate func observeCoinbaseAccountNotifications() {
        NotificationCenter.default.addObserver(forName: Notification.Name.coinbaseAuthenticationSuccess, object: nil, queue: nil) { [weak self] _ in
            self?.dismissSelf()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.coinbaseAuthenticationSuccess, object: nil, queue: nil) { [weak self] notification in
            let error = notification.object as? Error
            let alertController = UIAlertController(title: "Coinbase Error", message: "Failed to authenticate or retrieve yoru account error - \(error?.localizedDescription ?? "unknown.")]", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            self?.present(alertController, animated: true, completion: nil)
        }
    }
    
    fileprivate func delete(coinbaseAccount: CoinbaseAccount) {
        if coinbaseAccount.isInvalidated {
            return
        }
        
        let realm = try! Realm()
        realm.beginWrite()
        
        let coinbaseAccountWallets = realm.objects(Wallet.self).filter("%K = %@", #keyPath(Wallet.coinbaseWalletInfo.coinbaseAccount), coinbaseAccount)
        for wallet in coinbaseAccountWallets {
            Wallet.delete(wallet: wallet, commit: false)
        }
        
        realm.delete(coinbaseAccount)
        try? realm.commitWrite()
    }
}


extension SettingsViewController {
    enum Section : Int {
        case currency = 0
        case coinbase = 1
    }
}

