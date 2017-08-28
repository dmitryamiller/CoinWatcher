//
//  WalletTableCell.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/23/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit

class WalletTableCell: UITableViewCell {
    @IBOutlet weak var coinTypeLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var nativeAmountLabel: UILabel!
    
    var wallet: Wallet? {
        didSet {
            self.unwatchAll()
            
            guard let wallet = self.wallet else { return }
            let userPreferences = UserPreferences.current()
            
            self.watch(object: wallet, propertyName: #keyPath(Wallet.coinTypeId)) { [weak self] in
                guard false == (self?.wallet?.isInvalidated ?? true) else { return }
                self?.coinTypeLabel.text = self?.wallet?.coinType.rawValue
            }
            
            self.watch(object: wallet, propertyName: #keyPath(Wallet.name)) { [weak self] in
                guard false == (self?.wallet?.isInvalidated ?? true) else { return }
                self?.nameLabel.text = self?.wallet?.name
            }
            
            self.watch(object: wallet, propertyName: #keyPath(Wallet.ticker.price)) { [weak self] in
                guard false == (self?.wallet?.isInvalidated ?? true) else { return }
                self?.amountLabel.text = WalletTableCell.format(nativeBalance: self?.wallet?.nativeBalance,price: self?.wallet?.ticker?.price, currency: userPreferences.currency)
            }
            
            self.watch(object: wallet, propertyName: #keyPath(Wallet.nativeBalance)) { [weak self] in
                if wallet.nativeBalance < 0 {
                    self?.nativeAmountLabel.text = "--"
                    return
                }
                let formatter = NumberFormatter()
                formatter.positiveFormat = "#,###.0000 \(wallet.coinType.rawValue)"
                formatter.maximumFractionDigits = 4
                formatter.minimumFractionDigits = 4
                self?.nativeAmountLabel.text = formatter.string(from: wallet.nativeBalance as NSNumber)
            }
        }
    }
    
    override func prepareForReuse() {
        self.wallet = nil
    }
    
    private static func format(nativeBalance: Double?, price: Double?, currency: Currency) -> String? {
        guard let balance = nativeBalance,
              let price = price
        else { return "--" }
        
        if balance < 0 {
            return "--";
        }
        
        let formatter = NumberFormatter()
        formatter.positiveFormat = "\(currency.symbol)#,###.##"
        formatter.minimumFractionDigits = 2
        return formatter.string(from: balance * price as NSNumber)
    }
    
    
}
