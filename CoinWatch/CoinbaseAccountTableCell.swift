//
//  CoinbaseAccountTableCell.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 12/12/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit

class CoinbaseAccountTableCell: UITableViewCell {
    @IBOutlet weak var accountUsernameLabel: UILabel!
    @IBOutlet weak var accountExpiredImageView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    
    var coinbaseAccount: CoinbaseAccount? {
        didSet {
            self.unwatchAll()
            
            guard let coinbaseAccount = self.coinbaseAccount else { return }
            self.accountUsernameLabel.text = self.coinbaseAccount?.login
            
            self.watch(object: CurrentTimeManager.instance, propertyName: #keyPath(CurrentTimeManager.currentTime)) {
                if coinbaseAccount.isAuthenticationValid() {
                    self.accountExpiredImageView.isHidden = true
                    let willExpireInTimeInterval: TimeInterval = coinbaseAccount.accessTokenExpirationDate?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
                    self.statusLabel.text = "Authenticated. The token will expire in \(CoinbaseAccountTableCell.formatTimeTilExpiration(for: willExpireInTimeInterval))"
                } else {
                    self.accountExpiredImageView.isHidden = false
                    self.statusLabel.text = "Token Expired. You need to login to coinbase again to get up to date information."
                }
            }
            
        }
    }
    
    static func formatTimeTilExpiration(for timeInterval: TimeInterval) -> String {
        let now = Date().timeIntervalSince1970
        let diff = timeInterval - now
        if diff <= 0 {
            return "Expired"
        } else {
            let minutes = Int(diff / 60)
            let hours = Int(minutes / 60)
            var res = ""
            if hours > 0 {
                res += "\(hours) hr "
            }
            
            res += "\(minutes % 60) min"
            return res
        }
    }
    
}
