//
//  FormatUtils.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 12/12/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import Foundation

class FormatUtils {
    static func format(currency: Currency) -> String {
        return "\(currency.rawValue) (\(currency.symbol))"
    }
}
