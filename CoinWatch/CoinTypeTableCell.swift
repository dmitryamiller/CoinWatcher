//
//  CoinTypeTableCell.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/22/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit

class CoinTypeTableCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel?
    
    var coinType: CoinType? {
        didSet {
            self.nameLabel?.text = self.coinType?.name
        }
    }
}
