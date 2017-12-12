//
//  CurrentCurrencyTableCell.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/25/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit

class CurrentCurrencyTableCell: UITableViewCell {
    var userPreferences: UserPreferences? {
        didSet {
            self.unwatchAll()
            
            guard let userPreferences = self.userPreferences else { return }
            self.watch(object: userPreferences, propertyName: #keyPath(UserPreferences.currencyType)) { [weak self] in
                self?.textLabel?.text = FormatUtils.format(currency: userPreferences.currency)                    
            }
        }
    }
    
    override func prepareForReuse() {
        self.userPreferences = nil
    }
}
