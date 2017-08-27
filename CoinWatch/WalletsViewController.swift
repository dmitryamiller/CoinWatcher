//
//  WalletsViewController.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/22/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit
import RealmSwift

class WalletsViewController: UITableViewController {
    private var wallets: Results<Wallet>? {
        didSet {
            
        }
    }
    
    private var walletsToken: NotificationToken?
    
    deinit {
        self.walletsToken?.stop()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.estimatedRowHeight = 50
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.loadAndObserveWallets()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let selectCurrencyViewController = segue.destination as? SelectCurrencyViewController {
            selectCurrencyViewController.selectedCurrency = UserPreferences.current().currency
            selectCurrencyViewController.didSelectCurrency = { [weak self] currency in
                let realm  = try! Realm()
                realm.beginWrite()
                let userPrefererences = UserPreferences.current()
                if userPrefererences.currency != currency {
                    userPrefererences.currencyType = currency.rawValue
                }
                try! realm.commitWrite()
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    // MARK: - TableViewDataSource and TableViewDelegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tableSection = Section(rawValue: section) else { return 0 }
        
        switch tableSection {
            case .currency: return 1
            case .wallets: return max(self.wallets?.count ?? 0, 1)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else { fatalError() }
        
        switch section {
            case .currency:
                    let cell = tableView.dequeReusableCell(withType: CurrentCurrencyTableCell.self)
                    cell.userPreferences = UserPreferences.current()
                    return cell
            case .wallets:
                    if self.wallets?.count ?? 0 > 0 {
                        guard let wallets = self.wallets else { fatalError() }
                        let cell = tableView.dequeReusableCell(withType: WalletTableCell.self)
                        cell.wallet = wallets[indexPath.row]
                        return cell
                    } else {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "ZeroData")!
                        cell.textLabel?.text = NSLocalizedString("You have no wallets", comment: "No wallets")
                        return cell
                    }
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let section = Section(rawValue: indexPath.section) else { return false }
        switch section {
            case .currency: return false
            case .wallets: return self.wallets?.count ?? 0 > 0
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else { return  }
        
        switch section {
            case .currency: return
            case .wallets:
                guard let wallets = self.wallets else { return }
                switch editingStyle {
                case .insert, .none: return
                case .delete:
                    let wallet = wallets[indexPath.row]
                    self.delete(wallet: wallet)
                }
        }
        
    }
    
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
            case .currency:
                return "Currency"
            case .wallets:
                return "Wallets"
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    // MARK: - misc functions
    private func loadAndObserveWallets() {
        let sections = IndexSet(integer: Section.wallets.rawValue)
        let realm = try! Realm()
        self.walletsToken = realm.objects(Wallet.self).sorted(byKeyPath: #keyPath(Wallet.sortIndex), ascending: false).addNotificationBlock() { [weak self] changes in
            switch changes {
                case .initial(let wallets):
                    self?.wallets = wallets
                    self?.tableView.reloadSections(sections, with: .automatic)
                case .update(let wallets, let deletions, let insertions, _):
                    if deletions.count > 0 || insertions.count > 0 {
                        self?.wallets = wallets
                        self?.tableView.reloadSections(sections, with: .automatic)
                    }
                case .error: break
            }
        }
    }
    
    private func delete(wallet: Wallet) {
        let realm = try! Realm()
        realm.beginWrite()
        realm.delete(wallet)
        try! realm.commitWrite()
    }
}

extension WalletsViewController {
    enum Section : Int {
        case currency = 0
        case wallets = 1
    }
}
