//
//  CoinTransactionCell.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/30/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit

class CoinTransactionCell: UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var txHashLabel: UILabel!
    @IBOutlet weak var nativeAmountLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    
    var tx: CoinTransaction? {
        didSet {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/YYYY hh:mm:ss a"
            if let date = self.tx?.date {
                self.dateLabel.text = dateFormatter.string(from: date)
            } else {
                self.dateLabel.text = nil
            }
            
            self.txHashLabel.text = self.tx?.txHash
            
            self.unwatchAll()
            
            guard let tx = self.tx else { return }
            self.watch(object: tx, propertyName: #keyPath(CoinTransaction.wallet.ticker.price)) { [weak self] in
                guard false == tx.isInvalidated else { return }
                self?.nativeAmountLabel.text = CoinTransactionCell.format(nativeBalance: tx.nativeAmount, coinType: tx.wallet?.coinType)
                if let price = tx.wallet?.ticker?.price {
                    self?.amountLabel.text = CoinTransactionCell.format(nativeBalance: tx.nativeAmount, price: price, currency: UserPreferences.current().currency)
                } else {
                    self?.amountLabel.text = "--"
                }
                
                self?.amountLabel.textColor = tx.nativeAmount >= 0 ? UIColor.blue : UIColor.red
            }
        }
    }
    
    override func prepareForReuse() {
        self.tx = nil
    }
    
    private static func format(nativeBalance: Double?, coinType: CoinType?) -> String {
        guard let coinType = coinType,
              let nativeBalance = nativeBalance
        else { return "--" }
        let formatter = NumberFormatter()
        formatter.positiveFormat = "#,###.000 \(coinType.rawValue)"
        formatter.maximumFractionDigits = 4
        formatter.minimumFractionDigits = 4
        formatter.minimumIntegerDigits = 1
        return formatter.string(from: nativeBalance as NSNumber) ?? "--"
    }
    
    private static func format(nativeBalance: Double?, price: Double?, currency: Currency) -> String? {
        guard let balance = nativeBalance,
            let price = price
            else { return "--" }
        
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.positiveFormat = "\(currency.symbol)#,###.##"
        formatter.minimumFractionDigits = 2
        return formatter.string(from: balance * price as NSNumber)
    }
}
