//
//  CoinTransactionsViewController.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/30/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit
import RealmSwift
import PromiseKit
import SVPullToRefresh

class CoinTransactionsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private static let timeTransactionsValid: TimeInterval = 5
    
    @IBOutlet weak var walletCoinTypeImageView: UIImageView!
    @IBOutlet weak var walletNameLabel: UILabel!
    @IBOutlet weak var walletBalanceLabel: UILabel!
    @IBOutlet weak var walletNativeBalanceLabel: UILabel!
    @IBOutlet weak var walletLastTransactionSyncLabel: UILabel!
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var wallet: Wallet? {
        didSet {
            self.unwatchAll()
            
            if let wallet = self.wallet {
                self.observe(wallet: wallet)
            }
        }
    }
    
    var transactions = [CoinTransaction]()
    private var transactionsToken: NotificationToken?
    
    deinit {
        self.transactionsToken?.stop()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = NSLocalizedString("Recent Transactions", comment: "Recent Transactions title")
        
        self.tableView.estimatedRowHeight = 65
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.tableView.addPullToRefresh { [weak self] in
            guard let wallet = self?.wallet else { self?.tableView.pullToRefreshView.stopAnimating(); return }
            
            if Date().timeIntervalSince1970 - wallet.lastTxSync.timeIntervalSince1970  < CoinTransactionsViewController.timeTransactionsValid {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) {
                    self?.tableView.pullToRefreshView.stopAnimating()
                }
                
                return
            }
            
            self?.fetchTransactions().then {
                let realm = try! Realm()
                realm.beginWrite()
                wallet.lastTxSync = Date()
                try? realm.commitWrite()
                return AnyPromise(Promise<Void>())
            }.catch { error in
                if let coinbaseError = error as? CoinbaseManager.CoinbaseError {
                    self?.handleCoinbaseError(coinbaseError)
                }
            }.always {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) {
                    self?.tableView.pullToRefreshView.stopAnimating()
                }
            }
        }
        
        self.loadAndObserveTransactions()
        
        DispatchQueue.main.async { [weak self] in
            self?.tableView.triggerPullToRefresh()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
            case .zeroData: return self.transactions.count > 0 ? 0 : 1
            case .tx: return self.transactions.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
            case .zeroData:
                return tableView.dequeueReusableCell(withIdentifier: "ZeroData")!
            case .tx:
                let cell = tableView.dequeReusableCell(withType: CoinTransactionCell.self)
                cell.tx = self.transactions[indexPath.row]
                return cell
        }        
    }
    
    private func observe(wallet: Wallet) {
        let userPreferences = UserPreferences.current()
        
        self.watch(object: wallet, propertyName: #keyPath(Wallet.name)) { [weak self] in
            self?.walletNameLabel.text = wallet.name
        }
        
        self.watch(object: wallet, propertyName: #keyPath(Wallet.coinTypeId)) { [weak self] in
            self?.walletCoinTypeImageView.image = wallet.coinType.logoImage
        }
        
        let walletBalanceSetter = { [weak self] in
            guard false == (self?.wallet?.isInvalidated ?? true) else { return }
            self?.walletBalanceLabel.text = FormatUtils.formatAmount(nativeBalance: wallet.nativeBalance, price: wallet.ticker?.price, currency: userPreferences.currency)
        }
        
        
        self.watch(object: wallet, propertyNames: [#keyPath(Wallet.nativeBalance), #keyPath(Wallet.ticker.price)], coalescing: true, handler: walletBalanceSetter)
        self.watch(object: userPreferences, propertyName: #keyPath(UserPreferences.currencyType), handler: walletBalanceSetter)
        
        self.watch(object: wallet, propertyName: #keyPath(Wallet.nativeBalance)) { [weak self] in
            self?.walletNativeBalanceLabel.text = FormatUtils.formatNativeAmount(wallet.nativeBalance, wallet.coinType)
        }
        
        self.watch(object: wallet, propertyName: #keyPath(Wallet.lastTxSync)) { [weak self] in
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/YYYY hh:mm:ss a"
            self?.walletLastTransactionSyncLabel.text = formatter.string(from: wallet.lastTxSync)
        }
    }
    
    private func loadAndObserveTransactions() {
        guard let wallet = self.wallet else { return }
        self.transactionsToken = CoinTransaction.transactions(for: wallet).sorted(byKeyPath: #keyPath(CoinTransaction.date), ascending: false).addNotificationBlock() { [weak self] changes in
            switch changes {
                case .initial(let transactions):
                    self?.transactions = transactions.map { $0 }
                    self?.tableView.reloadData()
                case .update(let transactions, let deletions, let insertions, _):
                    if insertions.count > 0 || deletions.count > 0 {
                        self?.transactions = transactions.map { $0 }
                        self?.tableView.reloadData()
                    }
                case .error:
                    break
            }
        }
    }
    
    private func fetchTransactions() -> Promise<Void> {
        guard let wallet = self.wallet,
              let coinType = self.wallet?.coinType
        else { return Promise<Void>(error: CoinWatcherError.unknown) }
        
        if let _ = wallet.coinbaseWalletInfo {
            return CoinbaseManager.instance.fetchAndSyncTransactions(for: wallet)
        } else {
            switch coinType {
            case .bitcoin:
                return BitcoinManager.instance.fetchTransactions(for: wallet.address)
            case .bitcoinCash:
                return BitcoinCashManager.instance.fetchTransactions(for: wallet.address)
            case .etherium:
                return EtheriumManager.instance.fetchTransactions(for: wallet.address)
            case .dash:
                return DashManager.instance.fetchTransactions(for: wallet.address)
            case .litecoin:
                return LitecoinManager.instance.fetchTransactions(for: wallet.address)
            }
        }
    }
    
    private func handleCoinbaseError(_ coinbaseError: CoinbaseManager.CoinbaseError) {
        switch coinbaseError {
            case .invalidUrl: return
            case .unknownError: return
            case .notAuthenticated:
                let alert = UIAlertController(title: "Authentication Required", message: "You need to login to Coinbase to refresh your data. Proceed?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
                    CoinbaseManager.instance.startAuthentication()
                }))
                self.present(alert, animated: true, completion: nil)
        }
    }
}

extension CoinTransactionsViewController {
    enum Section : Int {
        case zeroData, tx
    }
}



