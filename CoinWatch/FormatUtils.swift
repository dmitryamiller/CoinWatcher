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
    
    // MARK: - Currency
    private static var currencyNumberFormatters = [String : NumberFormatter]()
    private static func currencyNumberFormatter(for currency: Currency) -> NumberFormatter {
        if let cachedNumberFormatter = self.currencyNumberFormatters[currency.rawValue] {
            return cachedNumberFormatter
        } else {
            let formatter = NumberFormatter()
            formatter.positiveFormat = "\(currency.symbol)#,###.##"
            formatter.minimumFractionDigits = 2
            formatter.minimumIntegerDigits = 1
            self.currencyNumberFormatters[currency.rawValue] = formatter
            return formatter
        }
    }
    
    static func formatAmount(nativeBalance: Double?, price: Double?, currency: Currency) -> String? {
        guard let balance = nativeBalance,
            let price = price
            else { return "--" }
        
        if balance < 0 {
            return "--";
        }
        
        return self.currencyNumberFormatter(for: currency).string(from: balance * price as NSNumber)
    }
    
    // MARK: - Coin native balance
    static func formatNativeAmount(_ nativeAmount: Double?, _ coinType: CoinType? ) -> String? {
        guard let nativeAmount = nativeAmount, let coinType = coinType else { return nil }
        
        let formatter = NumberFormatter()
        formatter.positiveFormat = "#,###.000 \(coinType.rawValue)"
        formatter.maximumFractionDigits = 4
        formatter.minimumFractionDigits = 4
        formatter.minimumIntegerDigits = 1
        return formatter.string(from: nativeAmount as NSNumber)
    }
}


