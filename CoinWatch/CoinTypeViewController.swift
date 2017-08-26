//
//  CoinTypeViewController.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/22/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit
import RealmSwift

class CoinTypeViewController: UITableViewController {
    var coinTypes: [CoinType] = CoinType.all
    var didSelectCointype: ((CoinType)->())?
    
    // MARK: -
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.coinTypes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeReusableCell(withType: CoinTypeTableCell.self)
        cell.coinType = self.coinTypes[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.didSelectCointype?(self.coinTypes[indexPath.row])
    }
    
    // MARK: -
    private func generateNewWalletName(for coinType: CoinType) -> String {
        let realm = try! Realm()
        let existingWallets = realm.objects(Wallet.self).filter("%K = %d", #keyPath(Wallet.coinTypeId), coinType.rawValue)
        return "\(coinType.name) Wallet" + (existingWallets.count > 0 ? " \(existingWallets.count + 1)" : "")
    }
}
