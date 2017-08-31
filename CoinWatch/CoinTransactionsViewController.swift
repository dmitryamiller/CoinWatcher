//
//  CoinTransactionsViewController.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/30/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit
import RealmSwift

class CoinTransactionsViewController: UITableViewController {
    var wallet: Wallet?
    
    private var transactions = [CoinTransaction]()
    private var transactionsToken: NotificationToken?
    
    deinit {
        self.transactionsToken?.stop()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.estimatedRowHeight = 65
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.loadAndObserveTransactions()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
            case .zeroData: return self.transactions.count > 0 ? 0 : 1
            case .tx: return self.transactions.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
            case .zeroData:
                return tableView.dequeueReusableCell(withIdentifier: "ZeroData")!
            case .tx:
                let cell = tableView.dequeReusableCell(withType: CoinTransactionCell.self)
                cell.tx = self.transactions[indexPath.row]
                return cell
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
}

extension CoinTransactionsViewController {
    enum Section : Int {
        case zeroData, tx
    }
}

