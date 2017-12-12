//
//  WalletsViewController.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/22/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit
import RealmSwift
import PromiseKit
import SVPullToRefresh

class WalletsViewController: UITableViewController {
    private static let timeWalletBalanceValid: TimeInterval = 10
    private var wallets: Results<Wallet>? 
    
    private var walletsToken: NotificationToken?
    private let totalModel = WalletTotalTableCell.Model()
    
    deinit {
        self.walletsToken?.stop()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.estimatedRowHeight = 50
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.loadAndObserveWallets()
        
        self.tableView.addPullToRefresh { [weak self] in
            self?.fetchWalletBalances().always {
                self?.tableView.pullToRefreshView.stopAnimating()
            }
        }
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
        } else if let transactionsViewController = segue.destination as? CoinTransactionsViewController {
            transactionsViewController.wallet = (sender as? WalletTableCell)?.wallet
        }
    }
    
    // MARK: - TableViewDataSource and TableViewDelegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tableSection = Section(rawValue: section) else { return 0 }
        
        switch tableSection {
            case .total: return 1
            case .wallets: return max(self.wallets?.count ?? 0, 1)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else { fatalError() }
        
        switch section {
            case .total:
                    let cell = tableView.dequeReusableCell(withType: WalletTotalTableCell.self)
                    cell.model = self.totalModel
                    return cell;
            
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
            case .total: return false
            case .wallets: return self.wallets?.count ?? 0 > 0
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else { return  }
        
        switch section {
            case .total: return
            case .wallets:
                guard let wallets = self.wallets else { return }
                switch editingStyle {
                case .insert, .none: return
                case .delete:
                    let wallet = wallets[indexPath.row]
                    Wallet.delete(wallet: wallet)
                }
        }
        
    }
    
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
            case .total:
                return "Total"
            case .wallets:
                return "Wallets"
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    // MARK: - misc functions
    private func loadAndObserveWallets() {
        var sections = IndexSet()
        sections.insert(Section.total.rawValue)
        sections.insert(Section.wallets.rawValue)
        
        let realm = try! Realm()
        self.walletsToken = realm.objects(Wallet.self).sorted(byKeyPath: #keyPath(Wallet.sortIndex), ascending: false).addNotificationBlock() { [weak self] changes in
            switch changes {
                case .initial(let wallets):
                    self?.wallets = wallets
                    self?.computeTotal()
                    self?.tableView.reloadSections(sections, with: .automatic)
                    let _ = self?.fetchWalletBalances()

                case .update(let wallets, let deletions, let insertions, _):
                    self?.computeTotal()
                    if insertions.count > 0 { // new wallet
                        let _ = self?.fetchWalletBalances()
                    }
                    if deletions.count > 0 || insertions.count > 0 {
                        self?.wallets = wallets
                        self?.tableView.reloadSections(sections, with: .automatic)
                    }
                
                
                case .error: break
            }
        }
    }
    
    private func fetchWalletBalances() -> Promise<Void> {
        let realm = try! Realm()
        var coinTypePromises = [Promise<Void>]()
        let timeUpdateAvailable = Date().addingTimeInterval(-WalletsViewController.timeWalletBalanceValid)
        
        for coinType in Set(realm.objects(Wallet.self)
                .filter("%K <= %@", #keyPath(Wallet.lastBalanceSync), timeUpdateAvailable)
                .map { $0.coinType }) {
                    switch coinType {
                        case .bitcoin:                        
                            coinTypePromises.append(BitcoinManager.instance.updateWalletBalances())
                        case .bitcoinCash:
                            coinTypePromises.append(BitcoinCashManager.instance.updateWalletBalances())
                        case .etherium:
                            coinTypePromises.append(EtheriumManager.instance.updateWalletBalances())
                        case .dash:
                            coinTypePromises.append(DashManager.instance.updateWalletBalances())
                        case .litecoin:
                            coinTypePromises.append(LitecoinManager.instance.updateWalletBalances())
                    }
        }
        
        print("updating for \(coinTypePromises.count) coin types")
        return when(fulfilled: coinTypePromises)
    }
    
    private func computeTotal() {
        guard let wallets = self.wallets else { self.totalModel.amount = -1; return }
        var total: Double = 0
        var validItemsExist = false
        for w in wallets {
            if w.nativeBalance < 0 {
                continue
            }
            
            guard let ticker = w.ticker else { continue }
            total += w.nativeBalance * ticker.price
            validItemsExist = true
        }
        
        self.totalModel.amount = validItemsExist ? total : -1
    }
}

extension WalletsViewController {
    enum Section : Int {
        case total = 0
        case wallets = 1
    }
}
