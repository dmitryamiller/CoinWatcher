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
    
    var coinbaseAccount: CoinbaseAccount? {
        didSet {
            self.accountUsernameLabel.text = self.coinbaseAccount?.login
        }
    }    
}
