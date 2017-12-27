//
//  CoinbaseWalletTableCell.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 12/26/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit

class CoinbaseWalletTableCell: WalletTableCell {
    @IBOutlet weak var warningIcon: UIImageView!
    
    override var wallet: Wallet? {
        didSet {
            
            guard let wallet = self.wallet else { return }
            let currentTimeManager = CurrentTimeManager.instance
            
            let updateWarningIcon: (()->()) = { [weak self] in
                self?.warningIcon.isHidden = wallet.coinbaseWalletInfo?.coinbaseAccount?.isAuthenticationValid() ?? true
            }
            
            
            self.watch(object: wallet, propertyName: #keyPath(Wallet.coinbaseWalletInfo.coinbaseAccount.accessTokenExpirationDate), handler: updateWarningIcon)
            self.watch(object: currentTimeManager, propertyName: #keyPath(CurrentTimeManager.currentTime), handler: updateWarningIcon)
        }
    }
}
