//
//  WalletTableCell.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/23/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit

class WalletTableCell: UITableViewCell {
    
    @IBOutlet weak var coinLogoIcon: UIImageView!
    @IBOutlet weak var coinbaseIndicatorIcon: UIImageView!
    @IBOutlet weak var coinTypeLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var nativeAmountLabel: UILabel!
    
    var wallet: Wallet? {
        didSet {
            self.unwatchAll()
            
            guard let wallet = self.wallet else { return }
            let userPreferences = UserPreferences.current()
            
            self.watch(object: wallet, propertyNames: [#keyPath(Wallet.coinTypeId), #keyPath(Wallet.coinbaseWalletInfo)]) { [weak self] in
                guard false == (self?.wallet?.isInvalidated ?? true) else { return }
                self?.coinTypeLabel.text = (self?.wallet?.coinType.rawValue ?? "") + (wallet.coinbaseWalletInfo != nil ? " - Coinbase" : "")
                
                self?.coinLogoIcon.image = self?.wallet?.coinType.logoImage
                self?.coinbaseIndicatorIcon.isHidden = wallet.coinbaseWalletInfo == nil
            }
            
            self.watch(object: wallet, propertyName: #keyPath(Wallet.name)) { [weak self] in
                guard false == (self?.wallet?.isInvalidated ?? true) else { return }
                self?.nameLabel.text = self?.wallet?.name
            }

            self.watch(object: wallet, propertyName: #keyPath(Wallet.nativeBalance)) { [weak self] in
                if wallet.nativeBalance < 0 {
                    self?.nativeAmountLabel.text = "--"
                    return
                }
                let formatter = NumberFormatter()
                formatter.positiveFormat = "#,###.000 \(wallet.coinType.rawValue)"
                formatter.maximumFractionDigits = 3
                formatter.minimumFractionDigits = 3
                formatter.minimumIntegerDigits = 1
                self?.nativeAmountLabel.text = formatter.string(from: wallet.nativeBalance as NSNumber)
            }
            
            let walletBalanceSetter = { [weak self] in
                guard false == (self?.wallet?.isInvalidated ?? true) else { return }
                self?.amountLabel.text = WalletTableCell.format(nativeBalance: self?.wallet?.nativeBalance,price: self?.wallet?.ticker?.price, currency: userPreferences.currency)
            }
            
            self.watch(object: wallet, propertyNames: [#keyPath(Wallet.nativeBalance), #keyPath(Wallet.ticker.price)], coalescing: true, handler: walletBalanceSetter)
            self.watch(object: userPreferences, propertyName: #keyPath(UserPreferences.currencyType), handler: walletBalanceSetter)
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
        formatter.minimumIntegerDigits = 1
        return formatter.string(from: balance * price as NSNumber)
    }
    
    
}
