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
                
                self?.nativeAmountLabel.text = FormatUtils.formatNativeAmount(wallet.nativeBalance, wallet.coinType)                
            }
            
            let walletBalanceSetter = { [weak self] in
                guard false == (self?.wallet?.isInvalidated ?? true) else { return }
                self?.amountLabel.text = FormatUtils.formatAmount(nativeBalance: self?.wallet?.nativeBalance, price: self?.wallet?.ticker?.price, currency: userPreferences.currency)
            }
            
            self.watch(object: wallet, propertyNames: [#keyPath(Wallet.nativeBalance), #keyPath(Wallet.ticker.price)], coalescing: true, handler: walletBalanceSetter)
            self.watch(object: userPreferences, propertyName: #keyPath(UserPreferences.currencyType), handler: walletBalanceSetter)
        }
    }
    
    override func prepareForReuse() {
        self.wallet = nil
    }
}
