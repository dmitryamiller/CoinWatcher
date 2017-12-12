//
//  CurrencyTableViewCell.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 12/12/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit

class CurrencyTableViewCell: UITableViewCell {
    @IBOutlet weak var currencyLabel: UILabel!
    
    var userPreferences: UserPreferences? {
        didSet {
            self.unwatchAll()
            
            guard let userPreferences = self.userPreferences else { return }
            self.watch(object: userPreferences, propertyName: #keyPath(UserPreferences.currencyType)) { [weak self] in
                self?.currencyLabel?.text = userPreferences.currency.rawValue + " (" + userPreferences.currency.symbol + ")"
            }
        }
    }
    
    override func prepareForReuse() {
        self.userPreferences = nil
    }
}
