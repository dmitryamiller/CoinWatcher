//
//  SelectCurrencyTableCell.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 12/12/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit
import RealmSwift

class SelectCurrencyTableCell: CurrencyTableViewCell {
    @IBOutlet weak var valuePickerView: UIPickerView!
    
    private let watcher = Object()
    
    override var userPreferences: UserPreferences? {
        didSet {
            self.watcher.unwatchAll()
            
            guard let userPreferences = self.userPreferences else { return }
            self.watcher.watch(object: userPreferences, propertyName: #keyPath(UserPreferences.currencyType)) { [weak self] in                
                guard let index = Currency.all.index(where: { $0.rawValue == userPreferences.currencyType }) else { return }
                self?.valuePickerView.selectRow(index, inComponent: 0, animated: true)
            }
        }
    }
}

extension SelectCurrencyTableCell : UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Currency.all.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let currency = Currency.all[row]
        return FormatUtils.format(currency: currency)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let realm = try! Realm()
        realm.beginWrite()
        
        let currency = Currency.all[row]
        UserPreferences.current().currencyType = currency.rawValue
        try? realm.commitWrite()
    }
    
}
