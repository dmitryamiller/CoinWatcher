//
//  WalletTotalTableCell.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/27/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit

class WalletTotalTableCell: UITableViewCell {
    @IBOutlet weak var amountLabel: UILabel!
    
    
    var model: Model? {
        didSet {
            self.unwatchAll()
            
            guard let model = self.model else { return }
            self.watch(object: model, propertyName: #keyPath(Model.amount)) { [weak self] in
                guard let amount = self?.model?.amount else { self?.amountLabel.text = "--"; return }
                if amount < 0 {
                    self?.amountLabel.text = "--"
                    return
                }
                
                let formatter = NumberFormatter()
                let userPreferences = UserPreferences.current()
                formatter.positiveFormat = userPreferences.currency.symbol + "#,###.00"
                formatter.minimumIntegerDigits = 1
                formatter.minimumFractionDigits = 2
                formatter.maximumFractionDigits = 2
                self?.amountLabel.text = formatter.string(from: amount as NSNumber)
            }
        }
    }
}

extension WalletTotalTableCell {
    class Model : NSObject {
        dynamic var amount: Double = -1
    }
}
